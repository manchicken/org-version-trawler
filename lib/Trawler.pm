package Trawler;

## no critic (ProhibitSubroutinePrototypes)
use Mojo::Base -signatures;
use Carp qw/cluck/;
use utf8;

use Mojo::Date;

use Git;
use PackageManager;
use Persistence;

sub new ($pkg, $opts = {}) {

  my $self = { %{$opts},
               persistence => Persistence->new(),
               git         => Git->new(),
             };

  my $db = $self->{persistence}->db;
  $self->{db} = $db;

  return bless $self, $pkg;
}

sub _should_skip_for_incremental_trawl ($self, $tree) {

  my $db = $self->{persistence}->db;

  my $found = $db->select('repository',
                          ['rowid'],
                          { name     => $tree->{repo}->{name},
                            org      => $tree->{repo}->{user},
                            sha      => $tree->{repo}->{sha},
                            archived => $tree->{repo}->{archived}
                          }
                         )->hash;

  return (exists $found->{rowid} and length $found->{rowid});
}

sub _record_repo ($self, $tree) {

  return if not $tree;

  my $repo_id =
    $self->{persistence}->upsert_repository(
    $tree->{repo}->{user}, $tree->{repo}->{name},
    $tree->{repo}->{sha},  $tree->{repo}->{archived},
    $tree->{repo}->{metadata},
                                           );
  say <<"EODEBUG";
Recorded repository $tree->{repo}->{user}/$tree->{repo}->{name} at <<$tree->{repo}->{sha}>>($tree->{repo}->{archived}) as repo ID $repo_id!
EODEBUG

  $tree->{repo_id} = $repo_id;

  # Upsert the contributors.
  my $contributors = $self->{git}
    ->get_contributors_for_repo($tree->{repo}->{user}, $tree->{repo}->{name});
  if ($contributors and scalar @{$contributors}) {
    $self->{persistence}->upsert_contributors($repo_id, $contributors);
  }

  return $tree;
}

sub get_repo_tree ($self, $user, $repo) {

  return $self->_record_repo($self->{git}->get_tree_for_repo($user, $repo));
}

sub next_repo_tree ($self, $org, $incremental, $stopper) {

  while (my $tree = $self->{git}->get_tree_for_next_repo) {
    last if ($stopper->());

    # For incremental scans, skip trees that we already know about.
    if ($incremental and $self->_should_skip_for_incremental_trawl($tree)) {
      next;
    }

    return $self->_record_repo($tree);
  }

  return;
}

sub next_package_blob ($self, $tree) {

  # Get the next package manager file.
  while (
    my $next_blob = $tree->next_node(

      # This is the filter function which verifies that
      # we have a package manager for the blob.
      sub {
        my ($item) = @_;

        return 1
          if ($item->{type} eq 'blob'
              and PackageManager->has_package_manager($item->{path}));
      }
    )
    )
  {

    # Get the package manager
    my $pkg_mgr = PackageManager->load($next_blob);
    if (not $pkg_mgr) {
      cluck "Despite having blob $next_blob->{path}, "
        . "I was unable to load the package manager.";
      next;
    }

    # Skip this file if there are no dependencies.
    next if not $pkg_mgr->has_dependencies;

    # Record the blob
    my $dep_file_id =
      $self->{persistence}->upsert_record(
                 'dependency_file',
                 { repository      => $tree->{repo_id},
                   path            => $next_blob->{path},
                   package_manager => $pkg_mgr->package_manager_details->{name},
                 }
      );
    say <<"EODEBUG";
Recorded dependency file $next_blob->{path} as file ID $dep_file_id.
EODEBUG

    $pkg_mgr->{dep_file_id} = $dep_file_id;
    return $pkg_mgr;
  }

  return;
}

sub trawl_repo_tree ($self, $tree) {

  # call $self->next_package_blob
  while (my $pkg_mgr = $self->next_package_blob($tree)) {
    return if not $pkg_mgr;

    # Iterate through the dependencies and record them.
    while (my $next_dep = $pkg_mgr->next_dependency) {

      # Record the dependencies.
      my $dep_version_id =
        $self->{persistence}->upsert_record(
                 'dependency_version',
                 { package_manager => $pkg_mgr->package_manager_details->{name},
                   package_name    => $next_dep->{package},
                   version_string  => $next_dep->{version},
                 }
        );
      say <<"EODEBUG";
Recorded dependency $next_dep->{package} with version $next_dep->{version} as dependency version ID $dep_version_id.
EODEBUG
      $self->{persistence}->upsert_record(
                                   'repository_dependency',
                                   { repository      => $tree->{repo_id},
                                     dependency_file => $pkg_mgr->{dep_file_id},
                                     dependency_version => $dep_version_id,
                                   }
      );
    }
  }

  return;
}

sub trawl_all ($self, $org = undef, $incremental = 0, $stopper = sub { 0 }) {

  $org ||= $ENV{GITHUB_USER_ORG};

  # Let's trawl the users...
  $self->trawl_users($org, $stopper);
  say STDERR "User pull is done.";

  # Loop over all of the repository trees
  while (my $tree = $self->next_repo_tree($org, $incremental, $stopper)) {
    $self->trawl_repo_tree($tree);
    last if $stopper->();
  }

  say STDERR "TRAWLER IS FINISHED.";

  return;
}

# Just return a single repo.
sub trawl_one ($self, $org, $repo) {

  my $tree = $self->get_repo_tree($org, $repo);
  return if not $tree;

  $self->trawl_repo_tree($tree);

  return $tree->{repo_id};
}

sub trawl_users ($self, $org, $stopper) {
  my $gh = $self->{git}->gh;

  my $org_instance = $gh->org;

  my $last_seen = Mojo::Date->new();
  while (my $user = $org_instance->next_member($org)) {
    last if $stopper->();
    say STDERR "Recording User <<$user->{login}>>";
    my $rowid =
      $self->{persistence}->upsert_record('org_member',
                                          { login      => $user->{login},
                                            type       => $user->{type},
                                            avatar_url => $user->{avatar_url},
                                            assumed_active => 'T',
                                          }
                                         );
    $self->{persistence}->db->update('org_member',
                                     { last_seen => $last_seen },
                                     { rowid     => $rowid });
  }
  $org_instance->close_member($org);

  my $inactive_date = Mojo::Date->new(time() - 60 * 60 * 12);
  say STDERR "Now Date: $last_seen";
  say STDERR "Inactive Date: $inactive_date";
  local $ENV{DBI_TRACE} = 99;
  $self->{persistence}->db->update('org_member',
                                   { assumed_active => 'F' },
                                   { last_seen => { '<' => $inactive_date } });

  return;
}

1;
