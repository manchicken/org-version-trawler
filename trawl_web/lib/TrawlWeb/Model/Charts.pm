package TrawlWeb::Model::Charts;

=pod

=head1 NAME

TrawlWeb::Model::Charts

=head1 DESCRIPTION

This model provides us with charting facilities.

=head1 METHODS

=over 4

=cut

## no critic (ProhibitSubroutinePrototypes)
use Mojo::Base q{TrawlWeb::Model}, -signatures;
use Mojo::Exception qw/raise/;

use Mojo::JSON qw/encode_json/;
use Mojo::Util qw/url_escape/;

use Readonly;

Readonly my $MAX_CHART_LENGTH => 512;

sub dependency_popularity_chart ($self, $package_manager) {
  return if !$package_manager;

  my $results = $self->db->query(<<'EOSQL', $package_manager);
select
  count(1) as popularity,
  package_name
from
  dependency_version
where
  package_manager = ?
group by
  package_name
order by
  popularity desc,
  package_name asc
;
EOSQL

  my @dependencies = ();
  my @counts       = ();
  my @items        = ();
  while (my $result = $results->hash) {
    push @dependencies, $result->{package_name};
    push @counts,       $result->{popularity};
    push @items,
      { label => $result->{package_name}, count => $result->{popularity} };
  }

  my $mt = Mojo::Template->new(vars => 1);

# TODO: This is old, and I should kill it soon.
# my $chart_content =
#   $self->get_chart_tpl(
#                        q{TrawlWeb::Plugin::Charts::DependencyPopularityChart},
#                        scalar @counts <= $MAX_CHART_LENGTH
#                        ? 'dependency_popularity_chart'
#                        : 'dependency_popularity_table'
#   );

  return { labels          => encode_json(\@dependencies),
           data            => encode_json(\@counts),
           items           => \@items,
           colorCount      => scalar @counts,
           package_manager => $package_manager,
           oversized_chart => scalar @counts > $MAX_CHART_LENGTH ? 1 : 0,
         };
}

1;

__END__

=back

=head1 SEE ALSO

C<TrawlWeb::Model>, C<Mojolicious>, C<Mojo::Base>, C<Mojo::SQLite>
