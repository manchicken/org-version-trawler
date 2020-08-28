package Persistence;

use Modern::Perl '2020';

## no critic (ProhibitSubroutinePrototypes)
use Mojo::Base -signatures;

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

sub sql ($self) {

  if (!exists $self->{_sql}) {
    $self->{_sql} = Mojo::SQLite->new($TrawlerConfig::SQL_FILE)
      ->options({ AutoCommit => 1, RaiseError => 1 });
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
  my ($self, $org, $repo, $sha, $archived, $metadata) = @_;

  my $db = $self->db;

  my $found = $db->query(<<'EOSQL', $repo, $org)->hash();
select
  rowid, name, org, sha, archived
from
  repository
where
  name = ? and org = ?
EOSQL

  # Just create the upsert record if it's missing.
  if (!$found) {
    return
      $self->upsert_record('repository',
                           { name     => $repo,
                             org      => $org,
                             sha      => $sha,
                             archived => $archived,
                             %{$metadata}
                           }
                          );
  }

  # If the sha matches, just return that.
  if ($found->{sha} eq $sha and $found->{archived} eq $archived) {
    return $found->{rowid};
  }

  # Here's the edge-case here! Let's update the SHA, and then return the rowid.
  $db->update('repository',
              { sha   => $sha, archived => $archived },
              { rowid => $found->{rowid} });
  return $found->{rowid};
}

sub upsert_contributors ($self, $repo_id, $contributors) {

  # Trash all of the existing records.
  $self->db->delete('repository_contributor', { repository => $repo_id });

  # Re-create the new ones.
  my $insert_count = 0;
  for my $one (@{$contributors}) {
    $self->db->insert('repository_contributor',
                      { repository => $repo_id,
                        %{$one}{qw/login avatar_url type contributions/}
                      }
                     );
    $insert_count += 1;
  }

  return $insert_count;
}

1;
