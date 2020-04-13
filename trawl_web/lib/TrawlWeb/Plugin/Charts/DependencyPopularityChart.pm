package TrawlWeb::Plugin::Charts::DependencyPopularityChart;

use Modern::Perl '2020';
use Mojo::JSON qw/encode_json/;
use Mojo::Util qw/url_escape/;

sub render {
  my ($chart, $c, $package_manager) = @_;

  return if !$package_manager;

  my $mt = Mojo::Template->new(vars => 1);
  my $chart_content =
    $chart->get_chart_tpl(
                         q{TrawlWeb::Plugin::Charts::DependencyPopularityChart},
                         'dependency_popularity_chart');

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
  having count(1) > 1
order by
  popularity desc,
  package_name asc
;
EOSQL

  my @dependencies = ();
  my @counts       = ();
  while (my $result = $results->hash) {
    push @dependencies, $result->{package_name};
    push @counts,       $result->{popularity};
  }

  return
    $mt->render($chart_content,
                { labels          => encode_json(\@dependencies),
                  data            => encode_json(\@counts),
                  colorCount      => scalar @counts,
                  package_manager => $package_manager,
                }
               );
}

1;

__DATA__

@@ dependency_popularity_chart.html.ep
% use TrawlWeb::Util qw/min_height/;
% my $height = min_height(int($colorCount) * 15);
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

