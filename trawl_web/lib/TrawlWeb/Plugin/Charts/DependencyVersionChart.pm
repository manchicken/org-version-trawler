package TrawlWeb::Plugin::Charts::DependencyVersionChart;

use Modern::Perl '2020';
use Mojo::JSON qw/encode_json/;

use PackageManager::Util qw/sort_semver/;

sub render {
  my ($chart, $c, $package_manager, $package_name) = @_;

  return if !$package_manager || !$package_name;

  my $mt = Mojo::Template->new(vars => 1);
  my $chart_content =
    $chart->get_chart_tpl(q{TrawlWeb::Plugin::Charts::DependencyVersionChart},
                          'dependency_version_chart');

  my $results = $chart->db->query(<<'EOSQL', $package_manager, $package_name);
select
  count(rd.rowid) as version_popularity,
  dv.version_string,
  dv.package_name
from
  dependency_version dv
join
  repository_dependency rd
    on (rd.dependency_version=dv.rowid)
where
  dv.package_manager = ?
and
  dv.package_name = ?
group by
  dv.package_manager, dv.package_name, dv.version_string
order by
  dv.version_string ASC
;
EOSQL

  my @versions = ();
  my @counts   = ();
  while (my $result = $results->hash) {
    push @versions, $result->{version_string};
    push @counts,   $result->{version_popularity};
  }

  # Handle empties.
  if (scalar @counts == 0) {
    return;
  }

  return
    $mt->render($chart_content,
                { labels          => encode_json(\@versions),
                  data            => encode_json(\@counts),
                  colorCount      => scalar @counts,
                  package_manager => $package_manager,
                  package_name    => $package_name,
                }
               );
}

1;

__DATA__

@@ dependency_version_chart.html.ep
% use TrawlWeb::Util qw/min_height/;
% my $height = min_height(int($colorCount) * 15);
<div style="width: 900px; height: <%=$height%>px;"><canvas style="width:900px; height:<%=$height%>px;" id="dependencyVersionChart"></canvas></div>
<script>
  const ctx = document.getElementById('dependencyVersionChart').getContext('2d')
  let chart = new Chart(ctx, {
    type: 'horizontalBar',
    data: {
      labels: <%= $labels %>,
      datasets: [{
        data: <%= $data %>,
        _foo: <%= int($colorCount) * 15 %>,
        backgroundColor: getChartColors(<%= $colorCount %>),
      }]
    },
    options: {
      legend: {display:false},
      scales: {
        xAxes: [{ ticks: { beginAtZero: true, suggestedMin: 1, precision: 0 } }],
        yAxes: [{ ticks: { beginAtZero: true, suggestedMin: 1, precision: 0 } }]
      },
      onClick: (e) => {
        const chartNode = chart.getElementsAtEvent(e)[0]
        window.chartNode = chartNode
        console.log(chartNode._model.label);

        const pkgVersion = <%= $labels %>[chartNode._index] || null;
        if (chartNode._model.label) {
          document.location.href = '/package_manager/<%= $package_manager %>/package_name/<%= $package_name %>/version/'+
            fixpath(pkgVersion);
        }
      }
    }
  })
</script>

