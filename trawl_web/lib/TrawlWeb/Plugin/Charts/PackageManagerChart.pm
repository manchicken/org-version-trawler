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
  count(1) as popularity,
  package_manager
from
  dependency_file
group by
  package_manager
order by
  package_manager asc
;
EOSQL

  my @labels = ();
  my @data   = ();
  while (my $result = $results->hash) {
    push @labels, $result->{package_manager};
    push @data,   $result->{popularity};
  }

  return
    $mt->render($chart_content,
                { labels     => encode_json(\@labels),
                  data       => encode_json(\@data),
                  colorCount => scalar @data,
                }
               );
}

1;

__DATA__

@@ package_manager_chart.html.ep
<div style="width: 900px;"><canvas style="width:900px;" id="packageManagerChart"></canvas></div>
<script>
  const ctx = document.getElementById('packageManagerChart').getContext('2d')
  let chart = new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels: <%= $labels %>,
      datasets: [{
        label: 'Package Manager',
        data: <%= $data %>,
        backgroundColor: getChartColors(<%= $colorCount %>),
      }]
    },
    options: {
      scales: {
        yAxes: [{
          ticks: { beginAtZero: true }
        }]
      },
      onClick: (e) => {
        const chartNode = chart.getElementsAtEvent(e)[0]
        window.chartNode = chartNode
        const pkgMgr = <%= $labels %>[chartNode._index] || null;
        if (chartNode._model.label) document.location.href = '/package_manager/'+encodeURI(pkgMgr);
        console.log(chartNode._model.label);
      }
    }
  })
</script>
