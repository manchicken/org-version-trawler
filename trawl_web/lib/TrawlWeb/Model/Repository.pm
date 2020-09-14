package TrawlWeb::Model::Repository;

## no critic (ProhibitSubroutinePrototypes)
use Mojo::Base q{TrawlWeb::Model}, -signatures;
use Mojo::Exception qw/raise/;

use Readonly;

use TrawlWeb::Model::RepositoryDependency;

has 'base_table' => 'repository';

# This is for the SQL queries.
Readonly my $UNMAINTAINED_PERIOD => '-4 year';

# This is for human readability.
Readonly our $UNMAINTAINED_PERIOD_DESCRIPTION => '4 calendar years from today';

sub find_by_name_pattern ($self, $name_pattern) {
  return
    $self->db->select($self->base_table, 'rowid,*',
                      { name => { -like => $name_pattern } },
                      [qw/org name/])->hashes;
}

sub count_unmaintained ($self) {
  return
    $self->db->select($self->base_table,
                      'count(rowid) as count_value',
                      {
                        last_commit => {
                          '<=' => \qq{date(date('now'), '$UNMAINTAINED_PERIOD')}
                        },
                        archived => 'F',
                      }
                     )->hash->{count_value};
}

sub count_vulnerable ($self) {
  return
    $self->db->select($self->base_table,
                      'count(rowid) as count_value',
                      { archived => 'F', vulnerability_count => { '>' => 0 }, }
                     )->hash->{count_value};
}

sub count_repos ($self) {
  return
    $self->db->select($self->base_table,
                      'count(rowid) as count_value',
                      { archived => 'F' })->hash->{count_value};
}

sub list_unmaintained ($self, $order = 'asc', @sort_cols) {
  if (0 == scalar @sort_cols) {

    # Default sort
    @sort_cols = qw/last_commit org name/;
  }

  for my $item (@sort_cols) {
    if (    $item ne 'org'
        and $item ne 'name'
        and $item ne 'last_commit'
        and $item ne 'last_committed_by'
        and $item ne 'vulnerability_count')
    {
      raise 'Invalid sort columns: ' . join(', ', @sort_cols);
    }
  }

  # Force to ascending if we don't have a valid one.
  if (lc $order ne 'asc' and lc $order ne 'desc') {
    $order = 'asc';
  }

  return
    $self->db->select($self->base_table,
                      'rowid,*',
                      {
                        last_commit => {
                          '<=' => \qq{date(date('now'), '$UNMAINTAINED_PERIOD')}
                        },
                        archived => 'F',
                      },
                      { "-$order" => \@sort_cols }
                     )->hashes;
}

sub list_vulnerable ($self, $order = 'asc', @sort_cols) {
  if (0 == scalar @sort_cols) {

    # Default sort
    @sort_cols = qw/last_commit org name/;
  }

  for my $item (@sort_cols) {
    if (    $item ne 'org'
        and $item ne 'name'
        and $item ne 'last_commit'
        and $item ne 'last_committed_by'
        and $item ne 'vulnerability_count')
    {
      raise 'Invalid sort columns: ' . join(', ', @sort_cols);
    }
  }

  # Force to ascending if we don't have a valid one.
  if (lc $order ne 'asc' and lc $order ne 'desc') {
    $order = 'asc';
  }

  return
    $self->db->select($self->base_table,
                      'rowid,*',
                      { vulnerability_count => { '>' => 0 },
                        archived            => 'F',
                      },
                      { "-$order" => \@sort_cols }
                     )->hashes;
}

1;
