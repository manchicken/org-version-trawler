package TrawlWeb::Model::OrgMember;

## no critic (ProhibitSubroutinePrototypes)
use Mojo::Base q{TrawlWeb::Model}, -signatures;

use Readonly;
use Data::Dumper;

has 'base_table' => 'org_member';
has 'cached_members';

sub invalidate_cache($self) {
  $self->cached_members({});

  return;
}

sub _populate_cache($self) {
  if (    $self->cached_members
      and ref $self->cached_members eq 'HASH'
      and scalar keys(%{ $self->cached_members }))
  {
    return;
  }

  my $values = $self->db->select($self->base_table)
    ->hashes->reduce(sub { $a->{ $b->{login} } = $b; $a }, {});
  $self->cached_members($values);

  return;
}

sub is_member ($self, $login) {
  $self->_populate_cache;

  return exists $self->cached_members->{$login}
    and $self->cached_members->{$login}->{assumed_active} eq 'T' ? 'T' : 'F';
}

1;
