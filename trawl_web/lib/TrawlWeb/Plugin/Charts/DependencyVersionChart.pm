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
  count(1) as version_popularity,
  version_string,
  package_name
from
  dependency_version
where
  package_manager = ?
and
  package_name = ?
group by
  package_name, version_string
;
EOSQL

  my @versions = ();
  my @counts   = ();
  while (my $result = $results->hash) {
    push @versions, $result->{version_string};
    push @counts,   $result->{version_popularity};
  }

  return
    $mt->render($chart_content,
                { labels =>
                    encode_json([ sort { sort_semver($a, $b) } @versions ]),
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
% sub min_height { my ($x) = @_; $x > 500 ? $x : 500; }
% my $height = min_height(int($colorCount) * 15);
<p>This chart shows all of the versions for the <%= $package_name %> dependency in the <%= $package_manager %> package manager.
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
        yAxes: [{
          ticks: { beginAtZero: true }
        }]
      }
    }
  })
</script>

