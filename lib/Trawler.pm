package Trawler;

use Modern::Perl '2020';
use Carp qw/cluck/;

use Git;
use PackageManager;
use Persistence;

sub new {
  my ($pkg, $opts) = @_;

  $opts ||= {};
  my $self = { %{$opts},
               persistence => Persistence->new(),
               git         => Git->new(),
             };

  my $db = $self->{persistence}->db;
  $self->{db} = $db;

  return bless $self, $pkg;
}

sub _record_repo {
  my ($self, $tree) = @_;

  return if not $tree;

  my $repo_id =
    $self->{persistence}->upsert_repository($tree->{repo}->{user},
                                            $tree->{repo}->{name},
                                            $tree->{repo}->{sha},
                                           );
  say <<"EODEBUG";
Recorded repository $tree->{repo}->{user}/$tree->{repo}->{name} at «$tree->{repo}->{sha}» as repo ID $repo_id.
EODEBUG

  $tree->{repo_id} = $repo_id;

  return $tree;
}

sub get_repo_tree {
  my ($self, $user, $repo) = @_;

  return $self->_record_repo($self->{git}->get_tree_for_repo($user, $repo));
}

sub next_repo_tree {
  my ($self) = @_;

  return $self->_record_repo($self->{git}->get_tree_for_next_repo);
}

sub next_package_blob {
  my ($self, $tree) = @_;

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

sub trawl_repo_tree {
  my ($self, $tree) = @_;

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

sub trawl_all {
  my ($self, $org) = @_;

  # Loop over all of the repository trees
  while (my $tree = $self->next_repo_tree($org)) {
    $self->trawl_repo_tree($tree);
  }

  return;
}

# Just return a single repo.
sub trawl_one {
  my ($self, $org, $repo) = @_;

  my $tree = $self->get_repo_tree($org, $repo);
  return if not $tree;

  $self->trawl_repo_tree($tree);

  return $tree->{repo_id};
}

1;
