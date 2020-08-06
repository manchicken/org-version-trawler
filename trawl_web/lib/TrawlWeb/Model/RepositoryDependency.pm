package TrawlWeb::Model::RepositoryDependency;

=pod

=head1 NAME

TrawlWeb::Model::RepositoryDependency

=head1 DESCRIPTION

This model gives us a window into the C<repository_dependency> table.

=head1 METHODS

=over 4

=cut

## no critic (ProhibitSubroutinePrototypes)
use Mojo::Base q{TrawlWeb::Model}, -signatures;
use Mojo::Exception qw/raise/;
use TrawlWeb::Model::RepositoryDependency;

has 'base_table' => 'repository_dependency';

=pod

=item C<find_by_repository($repository)

Find records based on the repository. You may pass either a repository ID, or the result of a C<TrawlWeb::Model::Repository> lookup.

=cut

sub find_by_repository ($self, $repository) {
  my $repo_id = ref $repository ? $repository->{rowid} : $repository;
  return $self->db->select($self->base_table, 'rowid,*',
                           { repository => $repo_id })->hashes;
}

=pod

=item C<find_by_repository_and_dependency_files($repository, $dependency_files>

Find C<repository_dependency> records based on repository and a list of dependency files.

For the C<$repository>, you may pass either a repository ID, or the result of a C<TrawlWeb::Model::Repository> lookup.

For the C<$dependency_files>, you may pass either an array of C<dependency_file.rowid> values, or you can pass in the C<Mojo::Collection> instance containing records from a C<TrawlWeb::Model::DependencyFile> lookup.

=cut

sub find_by_repository_and_dependency_files ($self, $repository,
                                             $dependency_files)
{
  my $repo_id      = ref $repository ? $repository->{rowid} : $repository;
  my $dep_file_ids = [];

  # We're really picky about what this can be. It's important that
  # it can boil down to an array of dependency_file.rowid values.
  if (ref $dependency_files eq 'ARRAY') {
    $dep_file_ids = $dependency_files;
  } elsif (ref $dependency_files eq 'HASH') {
    $dep_file_ids = $dependency_files->{rowid};
  } elsif (ref $dependency_files
           and $dependency_files->isa(q{Mojo::Collection}))
  {
    $dep_file_ids = $dependency_files->map(sub { $_->{rowid} })->to_array;
  } else {
    raise
'Invalid value passed for dependency_files. Must be arrayref or instance of Mojo::Collection.';
  }

  return
    $self->db->select($self->base_table,
                      'rowid,*',
                      { repository      => $repo_id,
                        dependency_file => $dep_file_ids,
                      }
                     )->hashes;
}

1;

__END__

=back

=head1 SEE ALSO

C<TrawlWeb::Model>, C<Mojolicious>, C<Mojo::Base>, C<Mojo::SQLite>
