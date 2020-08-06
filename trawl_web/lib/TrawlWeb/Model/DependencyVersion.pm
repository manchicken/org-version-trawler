package TrawlWeb::Model::DependencyVersion;

=pod

=head1 NAME

TrawlWeb::Model::DependencyVersion

=head1 DESCRIPTION

This model gives us a window into the C<dependency_version> table.

=head1 METHODS

=over 4

=cut

## no critic (ProhibitSubroutinePrototypes)
use Mojo::Base q{TrawlWeb::Model}, -signatures;
use Mojo::Exception qw/raise/;

has 'base_table' => 'dependency_version';

sub find_by_package_manager_and_package_name ($self, $package_manager,
                                              $package_name)
{
  return
    $self->db->select($self->base_table,
                      'rowid,*',
                      { package_manager => $package_manager,
                        package_name    => $package_name
                      },
                      { -asc =>
                          [qw/package_manager package_name version_string/]
                      }
                     )->hashes;
}

=pod

=item C<find_many($rowid_list)>

Find one or more records, in list context, based on a list of C<rowid> values.

For the C<$rowid_list>, you may pass in an array of C<dependency_version.rowid> values.

=cut

sub find_many ($self, $rowid_list) {
  return
    $self->db->select($self->base_table,
                      'rowid,*',
                      { rowid => { -in => $rowid_list } },
                      { -asc =>
                          [qw/package_manager package_name version_string/]
                      }
                     )->hashes;
}

1;

__END__

=back

=head1 SEE ALSO

C<TrawlWeb::Model>, C<Mojolicious>, C<Mojo::Base>, C<Mojo::SQLite>
