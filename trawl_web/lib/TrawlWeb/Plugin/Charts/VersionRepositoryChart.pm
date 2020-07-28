package TrawlWeb::Plugin::Charts::VersionRepositoryChart;

use Modern::Perl '2020';
use Mojo::JSON qw/encode_json/;

use PackageManager::Util qw/sort_semver/;

sub render {
  my ($chart, $c, $package_manager, $package_name, $package_version) = @_;

  # We need all of these values!
  if (not $package_manager or not $package_name or not $package_version) {
    say "Missing one of \$package_manager <<$package_manager>>, "
      . "\$package_name <<$package_name>>, "
      . "or \$package_version <<$package_version>>";
    return;
  }

  my $mt = Mojo::Template->new(vars => 1);
  my $chart_content =
    $chart->get_chart_tpl(q{TrawlWeb::Plugin::Charts::VersionRepositoryChart},
                          'version_repository_chart');

  my $results = $chart->db->query(
                                   <<'EOSQL', $package_manager, $package_name, $package_version);
select
  r.name,
  r.org,
  r.sha,
  df.path,
  df.package_manager
from
  dependency_version dv
join
  repository_dependency rd
    on (rd.dependency_version=dv.rowid)
join
  dependency_file df
    on (rd.dependency_file=df.rowid)
join
  repository r
    on (r.rowid=df.repository)
where
  dv.package_manager = ?
and
  dv.package_name = ?
and
  dv.version_string = ?
group by
  r.org, r.name, r.sha, df.package_manager, df.path
order by
  r.org, r.name, df.path, df.package_manager
;
EOSQL

  my @repos = ();
  while (my $result = $results->hash) {
    push @repos,
      { name => $result->{name},
        org  => $result->{org},
        sha  => $result->{sha},
        repo => join('/', $result->{org}, $result->{name}),
        path => $result->{path},
      };
  }

  # Handle empties.
  if (scalar @repos == 0) {
    return;
  }

  return
    $mt->render($chart_content,
                { repos           => \@repos,
                  package_manager => $package_manager,
                  package_name    => $package_name,
                  package_version => $package_version,
                }
               );
}

1;

__DATA__

@@ version_repository_chart.html.ep
<script>
const onClickFunc = (pkgName) => {
  return; // Nothing here yet.
//  if (pkgName) document.location.href = '/package_manager/<%= $package_manager %>/package_name/'+fixpath(pkgName);
}
</script>
<table class="chart">
  <thead>
    <tr>
      <th>Org</th>
      <th>Name</th>
      <th>Repository</th>
      <th>File Path</th>
    </tr>
  </thead>
  <tbody>
    % for my $item (@$repos) {
    <tr style="">
      <td><%= $item->{org} %></td>
      <td><%= $item->{name} %></td>
      <td><%= $item->{repo} %></td>
      <td>
        <a
          href="https://github.com/<%= $item->{repo} %>/blob/<%= $item->{sha} %>/<%= $item->{path} %>" target="_blank">
          <%= $item->{path} %>
        </a>
      </td>
    </tr>
    % }
  </tbody>
</table>
