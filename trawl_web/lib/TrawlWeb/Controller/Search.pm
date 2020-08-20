package TrawlWeb::Controller::Search;
use Mojo::Base 'Mojolicious::Controller';

# SIGNATURES BOILERPLATE
## no critic (ProhibitSubroutinePrototypes)
use feature qw(signatures);
no warnings qw(experimental::signatures);    ## no critic (ProhibitNoWarnings)

use Readonly;
use Mojo::Util qw/url_unescape/;

sub repo($self) {
  $self->session->{search_type} = 'repo';

  $self->stash(
      breadcrumbs =>
        [ { title => "Package Manager", url => q{/} }, { title => "Search" }, ],
      results => [],
      terms   => q//,
      message => q//,
  );

  # First, let's check our CSRF
  my $v = $self->validation;

  # Validate search parameters
  my $terms = url_unescape($v->required('terms')->param('terms'));
  if ($v->has_error) {
    return
      $self->render(message => 'Invalid search parameters: ' . $v->error,
                    status  => 400);
  }
  $self->session->{search_terms} = $terms;

  # Update the stash.
  $self->stash(
               breadcrumbs => [ { title => "Package Manager", url => q{/} },
                                { title => "Search: ${terms}" },
                              ],
               terms => $terms,
              );

  # Now that we've validated the params, let's perform a search.
  my $results =
    $self->repository->find_by_name_pattern(qq{\%$terms\%})->to_array;

  if (!scalar @{$results}) {
    return $self->stash(message => 'No results found',);
  }

  # Yield output to Mojo
  return
    $self->stash(results => $results,
                 message => scalar(@{$results}) . " results found.",);
}

1;
