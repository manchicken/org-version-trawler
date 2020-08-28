package TrawlWeb::Model::RepositoryContributor;

## no critic (ProhibitSubroutinePrototypes)
use Mojo::Base q{TrawlWeb::Model}, -signatures;

use Readonly;

has 'base_table' => 'repository_contributor';

sub find_by_repository ($self, $repository) {
  return
    $self->db->select($self->base_table, '*',
                      { repository => $repository },
                      { -desc      => [qw/contributions/] })->hashes;
}

1;
