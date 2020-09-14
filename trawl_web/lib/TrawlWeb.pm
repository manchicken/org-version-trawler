package TrawlWeb;
use Mojo::Base 'Mojolicious';

use FindBin qw/$Bin/;
use lib qq{$Bin/../lib};
use TrawlWeb::Controller::Trawl;
use Persistence;

use TrawlWeb::Model::Repository;
use TrawlWeb::Model::DependencyFile;
use TrawlWeb::Model::DependencyVersion;
use TrawlWeb::Model::RepositoryDependency;
use TrawlWeb::Model::Charts;
use TrawlWeb::Model::OrgMember;
use TrawlWeb::Model::RepositoryContributor;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Load configuration from hash returned by config file
  my $config = $self->plugin('Config');

  # Load the TagHelpers...
  $self->plugin('DefaultHelpers');
  $self->plugin('TagHelpers');

  # Load the Charts plugin
  $self->plugin('TrawlWeb::Plugin::Charts', {});
  $self->defaults(breadcrumbs => []);

  # Configure the application
  $self->secrets($config->{secrets});

  $self->helper(
    db => sub {
      my ($self) = @_;

      if (!exists $self->app->{persistence}) {
        $self->app->{persistence} = Persistence->new;
      }

      return $self->app->{persistence}->db;
    }

  );
  $self->helper(
    repository => sub {
      state $repository = TrawlWeb::Model::Repository->new(db => shift->db);
    }
  );
  $self->helper(
    dependency_file => sub {
      state $dependency_file =
        TrawlWeb::Model::DependencyFile->new(db => shift->db);
    }
  );
  $self->helper(
    dependency_version => sub {
      state $dependency_version =
        TrawlWeb::Model::DependencyVersion->new(db => shift->db);
    }
  );
  $self->helper(
    repository_dependency => sub {
      state $repository_dependency =
        TrawlWeb::Model::RepositoryDependency->new(db => shift->db);
    }
  );
  $self->helper(
    charts => sub {
      state $charts = TrawlWeb::Model::Charts->new(db => shift->db);
    }
  );
  $self->helper(
    org_member => sub {
      state $org_member = TrawlWeb::Model::OrgMember->new(db => shift->db);
    }
  );
  $self->helper(
    repository_contributor => sub {
      state $repository_contributor =
        TrawlWeb::Model::RepositoryContributor->new(db => shift->db);
    }
  );

  # Router
  my $r = $self->routes;

  # $r->add_type( version_number =>

  # Normal route to controller
  $r->get('/')->to('home#welcome');

  ## Admin and control plane endpoints
  $r->get('/health')->to('home#health');

  ## Browse the package manager hierarchy
  $r->get('/package_manager/:pkg_mgr_name')->to('home#package_manager');
  $r->get('/package_manager/:pkg_mgr_name/package_name/:pkg_name')
    ->to('home#package_name');
  $r->get(
    '/package_manager/:pkg_mgr_name/package_name/:pkg_name/version/:pkg_version'
      => [ pkg_version => qr/[^\/]+/xmsi ])->to('home#package_version');

  ## This triggers a manual trawl.
  # Use sparingly
  $r->get('/trawl')->to('trawl#run');
  $r->get('/trawl/:org/:repo')->to('trawl#run_for_one');

  ## Search endpoints
  $r->any('/search/repo')->to('search#repo');

  ## Repo search result browsing
  # TODO: Add parameter validation?
  $r->get('/repo/:repo_id/package_manager_files')
    ->to('repo#get_package_manager_files');
  $r->get('/repo/:repo_id/package_manager/:pkg_mgr_name')
    ->to('repo#get_package_manager');
  $r->get('/repo/:repo_id/dependency_file/:dep_file_id')
    ->to('repo#get_dependency_file');

  ## Unmaintained repository stuff.
  $r->get('/repo/unmaintained')->to('repo#get_unmaintained_report');
  $r->get('/repo/vulnerable')->to('repo#get_vulnerable_report');

  return;
}

1;
