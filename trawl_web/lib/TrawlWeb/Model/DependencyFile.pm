package TrawlWeb::Model::DependencyFile;

=pod

=head1 NAME

TrawlWeb::Model::DependencyFile

=head1 DESCRIPTION

This model gives us visibility into the C<dependency_file> table.

=head1 METHODS

=over 4

=cut

## no critic (ProhibitSubroutinePrototypes)
use Mojo::Base q{TrawlWeb::Model}, -signatures;

has 'base_table' => 'dependency_file';

=pod

=item C<find_by_repository($repository)>

This method allows us to select by repository ID. You may pass either a repository ID, or the result of a C<TrawlWeb::Model::Repository> lookup.

=cut

sub find_by_repository ($self, $repository) {
  my $repo_id = ref $repository ? $repository->{rowid} : $repository;

  return
    $self->db->select($self->base_table, 'rowid,*',
                      { repository => $repo_id },
                      { -asc       => [qw/package_manager path/] })->hashes;
}

=pod

=item C<find_by_repository_and_package_manager($repository, $package_manager)

This method allows you to fetch C<dependency_file> records based on the repository and a package manager name.

For the repository, pass in either a repository ID or the result of a C<TrawlWeb::Model::Repository> lookup.

=cut

sub find_by_repository_and_package_manager ($self, $repository,
                                            $package_manager)
{
  my $repo_id = ref $repository ? $repository->{rowid} : $repository;

  return
    $self->db->select($self->base_table,
                      'rowid,*',
                      { repository      => $repo_id,
                        package_manager => $package_manager
                      },
                      { -asc => [qw/package_manager path/] }
                     )->hashes;
}

1;

__END__

=back

=head1 SEE ALSO

C<TrawlWeb::Model>, C<Mojolicious>, C<Mojo::Base>, C<Mojo::SQLite>
