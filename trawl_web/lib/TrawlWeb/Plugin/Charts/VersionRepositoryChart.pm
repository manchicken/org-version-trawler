package TrawlWeb::Plugin::Charts::VersionRepositoryChart;

use Modern::Perl '2020';
use Mojo::JSON qw/encode_json/;

use PackageManager::Util qw/sort_semver/;

sub render {
  my ($chart, $c, $package_manager, $package_name, $package_version) = @_;

  # We need all of these values!
  if (not $package_manager or not $package_name or not $package_version) {
    say "Missing one of \$package_manager «$package_manager», "
      . "\$package_name «$package_name», "
      . "or \$package_version «$package_version»";
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
  r.sha
from
  dependency_version dv
join
  repository_dependency rd
    on (rd.dependency_version=dv.rowid)
join
  repository r
    on (r.rowid=rd.repository)
where
  dv.package_manager = ?
and
  dv.package_name = ?
and
  dv.version_string = ?
group by
  r.org, r.name, r.sha
order by
  r.org, r.name
;
EOSQL

  my @repos = ();
  while (my $result = $results->hash) {
    push @repos,
      { name => $result->{name},
        org  => $result->{org},
        sha  => $result->{sha},
        repo => join('/', $result->{org}, $result->{name})
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
<p>This chart shows all of the dependencies for <%= $package_manager %> having two or more consumers, sorted by popularity (irrespective of version) across all repositories, in descending order. For a full list of dependencies used in this package manager, SEE HERE(TODO).</p>
<script>
const onClickFunc = (pkgName) => {
  return; // Nothing here yet.
//  if (pkgName) document.location.href = '/package_manager/<%= $package_manager %>/package_name/'+fixpath(pkgName);
}
</script>
<table style="border-spacing: 0px; width: 900px; border: 1px solid black;">
  <thead>
    <tr>
      <th style="border:1px solid black;">Org</th>
      <th style="border:1px solid black;">Name</th>
      <th style="border:1px solid black;">Repository</th>
      <th style="border:1px solid black;">Commit SHA</th>
    </tr>
  </thead>
  <tbody>
    % for my $item (@$repos) {
    <tr style="">
      <td style="border:1px solid black;"><%= $item->{org} %></td>
      <td style="border:1px solid black;"><%= $item->{name} %></td>
      <td style="border:1px solid black;"><%= $item->{repo} %></td>
      <td style="border:1px solid black;">
        <a
          href="https://github.com/<%= $item->{repo} %>/tree/<%= $item->{sha} %>" target="_blank">
          <%= $item->{sha} %>
        </a>
      </td>
    </tr>
    % }
  </tbody>
</table>
