package TrawlWeb::Controller::Search;
use Mojo::Base 'Mojolicious::Controller';

# SIGNATURES BOILERPLATE
## no critic (ProhibitSubroutinePrototypes)
use feature qw(signatures);
no warnings qw(experimental::signatures);    ## no critic (ProhibitNoWarnings)

use Data::Dumper;
use Readonly;
use Persistence;

sub db {
  my ($self) = @_;

  if (!exists $self->app->{persistence}) {
    $self->app->{persistence} = Persistence->new;
  }

  return $self->app->{persistence}->db;
}

sub repo($self) {

  $self->stash(
      breadcrumbs =>
        [ { title => "Package Manager", url => q{/} }, { title => "Search" }, ],
      results   => [],
      repo_name => q//,
      message   => q//,
  );

  # First, let's check our CSRF
  my $v = $self->validation;
  if ($v->csrf_protect->has_error('csrf_token')) {
    return $self->render(message => 'Bad CSRF token!', status => 403);
  }

  # Validate search parameters
  my $repo_name = $v->required('repo_name')->param('repo_name');
  if ($v->has_error) {
    return
      $self->render(message => 'Invalid search parameters: ' . $v->error,
                    status  => 400);
  }

  # Update the stash.
  $self->stash(
               breadcrumbs => [ { title => "Package Manager", url => q{/} },
                                { title => "Search: ${repo_name}" },
                              ],
               repo_name => $repo_name,
              );

  # Now that we've validated the params, let's perform a search.
  my $db = $self->db;
  my $results =
    $db->select('repository', [qw/name org sha/],
                { name => { -like => "\%${repo_name}\%" } },
                [qw/org name/])->hashes->to_array;
  if (!scalar @{$results}) {
    return $self->stash(message => 'No results found',);
  }

  # Yield output to Mojo
  return
    $self->stash(results => $results,
                 message => scalar(@{$results}) . " results found.",);
}

1;
