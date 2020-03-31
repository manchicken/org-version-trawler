package Git::Tree;

use Modern::Perl '2020';

use Carp qw/croak/;

use Git::Tree::Entry;

sub new {
  my ($pkg, $data) = @_;

  my $self = { %$data, _index => 0 };

  # Really needs to be an ARRAYREF with at least one record.
  return if (ref $data->{tree} ne 'ARRAY' or scalar @{ $data->{tree} } < 1);

  return bless $self, $pkg;
}

sub next_node {
  my ($self, $filter) = @_;

  if (ref $filter and ref $filter ne 'CODE') {
    croak "Filters passed to `Git::Tree->next()` must be a CODEREF.";
  } elsif (!ref $filter) {
    $filter = sub { 1 };
  }

  # Go throughout the list
  while ($self->{_index} < scalar @{ $self->{tree} }) {
    my $value = Git::Tree::Entry->new(
                { %{ $self->{tree}->[ $self->{_index} ] }, gh => $self->{gh} });
    $self->{_index} += 1;

    # If the filter is satisfied, return the value.
    if ($filter->($value)) {
      return $value;
    }
  }
  return;
}

1;
