package TrawlWeb::Plugin::Charts::PackageManagerChart;

use Modern::Perl '2020';
use Mojo::JSON qw/encode_json/;

# Chart prints a graph which shows how popular each package management system is.
sub render {
  my ($chart, $c) = @_;

  my $mt = Mojo::Template->new(vars => 1);
  my $chart_content =
    $chart->get_chart_tpl(q{TrawlWeb::Plugin::Charts::PackageManagerChart},
                          'package_manager_chart');

  # say STDERR "RENDERING CHART!" . $chart_content;

  my $results = $chart->db->query(<<'EOSQL');
select
  count(dv.package_name) as popularity,
  dv.package_manager
from
  dependency_version dv
group by
  dv.package_manager
order by
  dv.package_manager asc
;
EOSQL

  my $managers = {};
  while (my $result = $results->hash) {
    $managers->{ $result->{package_manager} } = $result->{popularity};
  }

  return $mt->render($chart_content, { package_managers => $managers });
}

1;

__DATA__

@@ package_manager_chart.html.ep
<script>
const onClickFunc = (pkgMgrName) => {
  if (pkgMgrName) document.location.href = '/package_manager/'+fixpath(pkgMgrName);
}
</script>

<table class="chart">
  <thead>
    <tr>
      <th>Name</th>
      <th>Count</th>
    </tr>
  </thead>
  <tbody>
    % for my $package_manager (sort keys %{$package_managers}) {
      % my $count = $package_managers->{$package_manager};
    <tr class="linkish" onclick="onClickFunc('<%= $package_manager %>')">
      <td><%= $package_manager %></td>
      <td class="numeric"><%= $count %></td>
    </tr>
    % }
  </tbody>
</table>
