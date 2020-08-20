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

sub list_unmaintained ($self, $order = 'asc', @sort_cols) {
  if (not scalar @sort_cols) {

    # Default sort
    @sort_cols = qw/last_commit org name/;
  }

  if (!@sort_cols ~~ (qw/org name last_commit last_committed_by/)) {
    raise 'Invalid sort columns: ' . join(@sort_cols);
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

1;
