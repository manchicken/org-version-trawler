package TrawlWeb::Plugin::Charts;

use Mojo::Base 'Mojolicious::Plugin';

use Mojo::JSON qw/encode_json/;
use Mojo::Loader qw/data_section/;
use Mojo::Template;
use Data::Dumper;

use TrawlerConfig;
use Persistence;

use TrawlWeb::Plugin::Charts::PackageManagerChart;
use TrawlWeb::Plugin::Charts::DependencyPopularityChart;
use TrawlWeb::Plugin::Charts::DependencyVersionChart;
use TrawlWeb::Plugin::Charts::VersionRepositoryChart;

sub register {
  my ($self, $app, $conf) = @_;

  $self->{_refs} = { app  => $app,
                     conf => $conf,
                   };
  $self->db;

  $self->register_helpers($app);

  return $self;
}

sub register_helpers {
  my ($self, $app) = @_;

  $app->helper('chart_init', \&print_boilerplate);
  $app->helper(
    'package_manager_chart',
    sub {
      return TrawlWeb::Plugin::Charts::PackageManagerChart::render($self, @_);
    }
  );
  $app->helper(
    'dependency_popularity_chart',
    sub {
      return TrawlWeb::Plugin::Charts::DependencyPopularityChart::render($self,
                                                                         @_);
    }
  );
  $app->helper(
    'dependency_version_chart',
    sub {
      return TrawlWeb::Plugin::Charts::DependencyVersionChart::render($self,
                                                                      @_);
    }
  );
  $app->helper(
    'version_repository_chart',
    sub {
      return TrawlWeb::Plugin::Charts::VersionRepositoryChart::render($self,
                                                                      @_);
    }
  );

  return;
}

# Function to grab and cache the DB handle
sub db {
  my ($self) = @_;

  if (!exists $self->{_refs}->{app}->{persistence}) {
    $self->{_refs}->{app}->{persistence} = Persistence->new;
  }

  return $self->{_refs}->{app}->{persistence}->db;
}

sub print_boilerplate {
  return data_section('TrawlWeb::Plugin::Charts', 'boilerplate.html');
}

sub get_chart_tpl {
  my ($self, $pkg, $name) = @_;

  if (!$name) {
    $name = $pkg;
    $pkg  = 'TrawlWeb::Plugin::Charts';
  }

  return data_section($pkg, "${name}.html.ep")
    || "UNKNOWN TEMPLATE: ${name}.html.ep";
}

1;

__DATA__

@@ boilerplate.html
<script src="https://cdn.jsdelivr.net/npm/chart.js@2.9.3/dist/Chart.min.js"
  integrity="sha256-R4pqcOYV8lt7snxMQO/HSbVCFRPMdrhAFMH+vr9giYI=" crossorigin="anonymous"></script>
<script type="application/javascript" src="/js/chart.js"></script>
