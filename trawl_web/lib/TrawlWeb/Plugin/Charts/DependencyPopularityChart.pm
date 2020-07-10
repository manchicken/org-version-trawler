package TrawlWeb::Plugin::Charts::DependencyPopularityChart;

use Modern::Perl '2020';
use Mojo::JSON qw/encode_json/;
use Mojo::Util qw/url_escape/;
use Readonly;

Readonly my $MAX_CHART_LENGTH => 1024;

sub render {
  my ($chart, $c, $package_manager) = @_;

  return if !$package_manager;

  my $results = $chart->db->query(<<'EOSQL', $package_manager);
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
  my $chart_content =
    $chart->get_chart_tpl(
                         q{TrawlWeb::Plugin::Charts::DependencyPopularityChart},
                         scalar @counts <= $MAX_CHART_LENGTH
                         ? 'dependency_popularity_chart'
                         : 'dependency_popularity_table'
    );

  return
    $mt->render($chart_content,
                { labels          => encode_json(\@dependencies),
                  data            => encode_json(\@counts),
                  items           => \@items,
                  colorCount      => scalar @counts,
                  package_manager => $package_manager,
                }
               );
}

1;

__DATA__

@@ dependency_popularity_table.html.ep
# This is for use when the list of dependencies is just too big to fit into a browser.
<p>This chart shows all of the dependencies for <%= $package_manager %> having two or more consumers, sorted by popularity (irrespective of version) across all repositories, in descending order. For a full list of dependencies used in this package manager, SEE HERE(TODO).</p>
<script>
const onClickFunc = (pkgName) => {
  if (pkgName) document.location.href = '/package_manager/<%= $package_manager %>/package_name/'+fixpath(pkgName);
}
</script>
<table style="border-spacing: 0px; width: 900px; border: 1px solid black;">
  <thead>
    <tr>
      <th style="border:1px solid black;">Name</th>
      <th style="border:1px solid black;">Count</th>
    </tr>
  </thead>
  <tbody>
    % for my $item (@$items) {
    <tr style="color: blue; text-decoration: underline" onclick="onClickFunc('<%= $item->{label} %>')">
      <td style="border:1px solid black;"><%= $item->{label} %></td>
      <td style="border:1px solid black;"><%= $item->{count} %></td>
    </tr>
    % }
  </tbody>
</table>

@@ dependency_popularity_chart.html.ep
% use TrawlWeb::Util qw/min_height/;
% my $height = min_height(int($colorCount) * 35);
<p>This chart shows all of the dependencies for <%= $package_manager %> having two or more consumers, sorted by popularity (irrespective of version) across all repositories, in descending order. For a full list of dependencies used in this package manager, SEE HERE(TODO).</p>
<div style="width: 900px; height: <%=$height%>px;"><canvas style="width:900px; height:<%=$height%>px;" id="dependencyPopularityChart"></canvas></div>
<script>
  const ctx = document.getElementById('dependencyPopularityChart').getContext('2d')
  let chart = new Chart(ctx, {
    type: 'horizontalBar',
    data: {
      labels: <%= $labels %>,
      datasets: [{
        data: <%= $data %>,
        backgroundColor: getChartColors(<%= $colorCount %>),
      }]
    },
    options: {
      legend: {display:false},
      scales: {
        xAxes: [{ ticks: { beginAtZero: true, suggestedMin: 1, precision: 0 } }],
        yAxes: [{
          ticks: { beginAtZero: true, suggestedMin: 1, precision: 0 }
        }]
      },
      onClick: (e) => {
        const chartNode = chart.getElementsAtEvent(e)[0]
        window.chartNode = chartNode
        console.log(chartNode._model.label);

        const pkgName = <%= $labels %>[chartNode._index] || null;
        if (chartNode._model.label) document.location.href = '/package_manager/<%= $package_manager %>/package_name/'+fixpath(pkgName);
      }
    }
  })
</script>

