package TrawlWeb::Controller::Home;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub welcome {
  my ($self) = @_;

  $self->stash(breadcrumbs => [ { title => "Package Manager" } ]);

  # Render template "example/welcome.html.ep" with message
  return $self->stash(
                  msg => 'Welcome to the Mojolicious real-time web framework!');
}

sub package_manager {
  my ($self) = @_;

  my $pkg_mgr_name = $self->param('pkg_mgr_name') || 'UNKNOWN';
  $self->stash(
               breadcrumbs => [ { title => "Package Manager", url => q{/} },
                                { title => $pkg_mgr_name },
                              ]
              );

  return $self->stash(pkg_mgr_name => $pkg_mgr_name);
}

sub package_name {
  my ($self) = @_;

  my $pkg_mgr_name = $self->param('pkg_mgr_name') || 'UNKNOWN';
  my $pkg_name     = $self->param('pkg_name')     || 'UNKNOWN';
  $self->stash(
        breadcrumbs => [
          { title => "Package Manager", url => q{/} },
          { title => $pkg_mgr_name, url => qq{/package_manager/$pkg_mgr_name} },
          { title => $pkg_name },
        ]
  );

  return $self->stash(pkg_mgr_name => $pkg_mgr_name);
}

1;
