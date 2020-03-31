package Persistence;

use Modern::Perl '2020';

use Syntax::Keyword::Try;
use Carp qw/confess/;
use Readonly;
use Data::Dumper;
use Mojo::SQLite;

use TrawlerConfig;
use Persistence::Startup;

sub new {
  my ($pkg) = @_;

  my $self = {};

  return bless $self, $pkg;
}

sub sql {
  my ($self) = @_;

  if (!exists $self->{_sql}) {
    $self->{_sql} = Mojo::SQLite->new($TrawlerConfig::SQL_FILE);
    Persistence::Startup->startup($self->{_sql});
  }
  return $self->{_sql};
}

sub db {
  my ($self) = @_;

  return $self->sql->db;
}

sub upsert_record {
  my ($self, $table, @values) = @_;

  my $db = $self->db;

  my $found = $db->select($table, ['rowid'], @values)->hash;
  return $found->{rowid} if ($found and exists $found->{rowid});

  try { return $db->insert($table, @values)->last_insert_id; }
  catch {
    say STDERR "WHILE INSERTING:" . Dumper(\@values);
    confess $@;
  };

  return;
}

sub upsert_repository {
  my ($self, $org, $repo, $sha) = @_;

  my $db = $self->db;

  my $found = $db->query(<<'EOSQL', $repo, $org)->hash();
select
  rowid, name, org, sha
from
  repository
where
  name = ? and org = ?
EOSQL

  # Just create the upsert record if it's missing.
  if (!$found) {
    return
      $self->upsert_record('repository',
                           { name => $repo,
                             org  => $org,
                             sha  => $sha,
                           }
                          );
  }

  # If the sha matches, just return that.
  if ($found->{sha} eq $sha) {
    return $found->{rowid};
  }

  # Here's the edge-case here! Let's update the SHA, and then return the rowid.
  $db->update('repository', { sha => $sha }, { rowid => $found->{rowid} });
  return $found->{rowid};
}

1;
