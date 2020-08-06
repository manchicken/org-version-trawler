package TrawlWeb::Model::Repository;

## no critic (ProhibitSubroutinePrototypes)
use Mojo::Base q{TrawlWeb::Model}, -signatures;

use TrawlWeb::Model::RepositoryDependency;

has 'base_table' => 'repository';

sub find_by_name_pattern ($self, $name_pattern) {
  return
    $self->db->select($self->base_table, 'rowid,*',
                      { name => { -like => $name_pattern } },
                      [qw/org name/])->hashes;
}

1;
