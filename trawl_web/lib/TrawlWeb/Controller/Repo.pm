package TrawlWeb::Controller::Repo;

=pod

=head1 NAME

TrawlWeb::Controller::Repo

=head1 DESCRIPTION

This Mojo controller allows us to do things within a single repository, such as search by name, view files and package managers, and view dependencies.

=head1 ACTIONS

=over 4

=cut

## no critic (ProhibitSubroutinePrototypes)
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::Util qw/xml_escape/;

use Readonly;
use PackageManager::Util qw/sort_semver/;
use Data::Dumper;

=pod

=item C<search_url()>

=cut

sub search_url($self) {
  my $search_type  = $self->session->{search_type}  || 'repo';
  my $search_terms = $self->session->{search_terms} || 'Unknown Search';
  return $self->url_for("/search/${search_type}")
    ->query(terms => $search_terms);
}

sub get_package_manager_files ($self) {
  my $repo_id = $self->param('repo_id');

  # All of the $back_behavior stuff is a
  # stop-gap to the older approach of the charts.
  my $back_behavior =
    ($self->param('ref') and $self->param('ref') eq 'back') ? 1 : 0;

  $self->stash(
            message     => q{},
            breadcrumbs => [
              { title => "Package Manager", url => q{/} },
              { title => $back_behavior ? "Repository Chart" : "Search Results",
                url   => $back_behavior
                ? 'javascript:history.back()'
                : $self->search_url,
              },
              { title => 'Repository View' }
            ],
            repo_name => q{},
            repo_org  => q{},
            results   => [],
            repo_id   => $repo_id,
            repo_sha  => q{},
  );

  my $repo_deets = $self->repository->find($repo_id);

  # Make sure that this is legit
  if (not $repo_deets or not exists $repo_deets->{name}) {
    return $self->render(message => 'No such repository.', status => 404);
  }

  $self->stash(
            breadcrumbs => [
              { title => "Package Manager", url => q{/} },
              { title => $back_behavior ? "Repository Chart" : "Search Results",
                url   => $back_behavior
                ? 'javascript:history.back()'
                : $self->search_url,
              },
              { title => "Repository: $repo_deets->{org}/$repo_deets->{name}" }
            ],
            repo_name => $repo_deets->{name},
            repo_org  => $repo_deets->{org},
            repo_sha  => $repo_deets->{sha},
  );

  my $results =
    $self->dependency_file->find_by_repository($repo_deets)->to_array;
  if (!scalar @{$results}) {
    return $self->stash(message => 'No package manger files found.');
  }

  return $self->stash(results => $results);
}

=pod

=item C<get_package_manager()>

This action allows us to view the dependencies within a repository, but for a specific package manager.

The use case here is that I search and find a repository, but want to find all of the NPM dependencies within it.

=cut

sub get_package_manager($self) {
  my $repo_id      = $self->param('repo_id');
  my $pkg_mgr_name = $self->param('pkg_mgr_name');

  $self->stash(message     => q{},
               breadcrumbs => [ { title => "Package Manager", url => q{/} },
                                { title => "Search Results",
                                  url   => $self->search_url,
                                },
                                { title => 'Repository View' }
                              ],
               repo_name => q{},
               repo_org  => q{},
               results   => [],
               repo_id   => $repo_id,
              );

  # Get some information regarding the repository
  my $repo_deets = $self->repository->find($repo_id);

  # Make sure that this is legit
  if (not $repo_deets or not exists $repo_deets->{name}) {
    return $self->render(message => 'No such repository.', status => 404);
  }

  # Update breadcrumbs.
  $self->stash(
            breadcrumbs => [
              { title => "Package Manager", url => q{/} },
              { title => "Search Results",
                url   => $self->search_url,
              },
              { title => "Repository: $repo_deets->{org}/$repo_deets->{name}",
                url => $self->url_for("/repo/${repo_id}/package_manager_files"),
              },
              { title => $pkg_mgr_name }
            ],
            repo_name => $repo_deets->{name},
            repo_org  => $repo_deets->{org}
  );

  # Get the dependency_file records for the repository.
  my $dep_files =
    $self->dependency_file->find_by_repository_and_package_manager($repo_id,
                             $pkg_mgr_name)->map(sub { $_->{rowid} })->to_array;

  # Get the dependencies from the dependency_file records
  my $rep_deps =
    $self->repository_dependency->find_by_repository_and_dependency_files(
                   $repo_id,
                   $dep_files)->map(sub { $_->{dependency_version} })->to_array;

  # Get the dependency version info, and reduce it to something usable.
  my $results = $self->dependency_version->find_many($rep_deps)->reduce(
    sub {
      $a->{ $b->{package_name} } ||= [];
      $a->{ $b->{package_name} } = [ sort { sort_semver($a, $b) }
                      (@{ $a->{ $b->{package_name} } }, $b->{version_string}) ];
      $a;
    },
    {}
                                                                       );

  # Update the results in the stash.
  return $self->stash(results => $results);
}

=pod

=item C<get_dependency_file()>

This action displays details about a specific dependency file.

=cut

sub get_dependency_file($self) {
  my $repo_id     = $self->param('repo_id');
  my $dep_file_id = $self->param('dep_file_id');

  $self->stash(message     => q{},
               breadcrumbs => [ { title => "Package Manager", url => q{/} },
                                { title => "Search Results",
                                  url   => $self->search_url,
                                },
                                { title => 'Dependency File View' }
                              ],
               repo_name => q{},
               repo_org  => q{},
               results   => {},
               repo_id   => $repo_id,
               dep_file  => {path            => q//,
                             package_manager => q//,
                             repository      => 0,
                             rowid           => $dep_file_id
                           }
              );

  # Get some information regarding the repository
  my $repo_deets = $self->repository->find($repo_id);

  # Make sure that this is legit
  if (not $repo_deets or not exists $repo_deets->{name}) {
    return $self->render(message => 'No such repository.', status => 404);
  }

  # Need to get the dependency file, too.
  my $dep_file = $self->dependency_file->find($dep_file_id);
  if (not $dep_file or not exists $dep_file->{path}) {
    return $self->render(message => 'No such dependency file.', status => 404);
  }

  # Update breadcrumbs.
  $self->stash(
            breadcrumbs => [
              { title => "Package Manager", url => q{/} },
              { title => "Search Results",
                url   => $self->search_url,
              },
              { title => "Repository: $repo_deets->{org}/$repo_deets->{name}",
                url => $self->url_for("/repo/${repo_id}/package_manager_files"),
              },
              { title => $dep_file->{path} }
            ],
            repo_name => $repo_deets->{name},
            repo_org  => $repo_deets->{org},
            dep_file  => $dep_file,
  );

  # Get the dependencies from the dependency_file records
  my $rep_deps =
    $self->repository_dependency->find_by_repository_and_dependency_files(
                    $repo_id,
                    $dep_file)->map(sub { $_->{dependency_version} })->to_array;

  # Get the dependency version info, and reduce it to something usable.
  my $results = $self->dependency_version->find_many($rep_deps)->reduce(
    sub {
      $a->{ $b->{package_name} } ||= [];
      $a->{ $b->{package_name} } = [ sort { sort_semver($a, $b) }
                      (@{ $a->{ $b->{package_name} } }, $b->{version_string}) ];
      $a;
    },
    {}
                                                                       );

  # Update the results in the stash.
  return $self->stash(results => $results);
}

=pod

=item C<get_unmaintained_report()>

This action displays the report of unmaintained repositories.

=cut

Readonly my $SORT_ORDERS => {
              name              => [qw/org name last_commit/],
              last_commit       => [qw/last_commit org name/],
              last_committed_by => [qw/last_committed_by last_commit org name/],
};

sub get_unmaintained_report($self) {
  my $sort_pref = $self->param('sort')  || 'last_commit';
  my $order     = $self->param('order') || 'asc';

  $self->stash(
     message     => q{},
     breadcrumbs => [ { title => "Package Manager", url => q{/} },
                      { title => 'Unmaintained Repositories' }
                    ],
     results => [],
     unmaintained_period_description =>
       $TrawlWeb::Model::Repository::UNMAINTAINED_PERIOD_DESCRIPTION || q{ACK!},
  );

  # Validate sort order
  my @sort_cols = qw/last_commit org name/;
  if (not exists $SORT_ORDERS->{$sort_pref}) {
    $self->stash(message => 'Invalid sort order: ' . xml_escape($sort_pref));
  } else {
    @sort_cols = @{ $SORT_ORDERS->{$sort_pref} };
  }

  # Force to ascending if we don't have a valid one.
  if (lc $order ne 'asc' and lc $order ne 'desc') {
    $order = 'asc';
  }

  # Make the call out to the model
  my $unmaintained_list =
    $self->repository->list_unmaintained($order, @sort_cols)->to_array;
  if (not scalar @{$unmaintained_list}) {
    $self->stash(
         message => q{No unmaintained repositories. Wow. That's really great.});
  }

  # Add the contributors
  for my $result (@{$unmaintained_list}) {
    my $contributors =
      $self->repository_contributor->find_by_repository($result->{rowid})
      ->reduce(
      sub {
        $b->{is_member} = $self->org_member->is_member($b->{login});
        push @{$a}, $b;
        $a;
      },
      []
              );
    $result->{contributors} = $contributors;
  }

  return
    $self->stash(results   => $unmaintained_list,
                 order     => $order,
                 sort_pref => $sort_pref
                );
}

1;

__END__

=back

=head1 SEE ALSO

C<TrawlWeb::Model>, C<Mojolicious>, C<Mojo::Base>, C<Mojo::SQLite>
