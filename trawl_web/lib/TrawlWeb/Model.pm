package TrawlWeb::Model;

## no critic (ProhibitSubroutinePrototypes)
use Mojo::Base -base, -signatures;

has 'db';
has 'app';
has 'base_table' => 'UNKNOWN';

sub find ($self, $id) {
  return $self->db->select($self->base_table, 'rowid,*', { rowid => $id })
    ->hash;
}

1;
