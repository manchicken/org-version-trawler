package TrawlWeb::Controller::Trawl;
use Mojo::Base 'Mojolicious::Controller';

# SIGNATURES BOILERPLATE
## no critic (ProhibitSubroutinePrototypes)
use feature qw(signatures);
no warnings qw(experimental::signatures);    ## no critic (ProhibitNoWarnings)

# END SIGNATURES BOILERPLATE

use Trawler;

use Mojo::Date;
use Mojo::IOLoop::Subprocess;
use Readonly;

# 12 hours
Readonly my $TRAWL_TIMER => 60 * 60 * 12;

my $subprocess                  = Mojo::IOLoop::Subprocess->new;
my $runner_start_time           = 0;
my $runner_last_finish_duration = 0;
my $runner_running              = 0;
my $run_count                   = 0;
my $timer_id                    = '';
my $toplevel_pid                = $$;

sub set_timer {
  my $time_offset = $run_count > 0 ? $TRAWL_TIMER : 1;
  say STDERR "SETTING TRAWLER TIMER FOR $time_offset SECONDS.";

  # Kill any existing timers.
  if (length $timer_id) {
    say STDERR "Killing old timer.";
    $subprocess->ioloop->remove($timer_id);
  }

  $timer_id = $subprocess->ioloop->timer(
    $time_offset,
    sub {
      # Skip if the trawler is already running, just reset the timer.
      if ($runner_running) {
        TrawlWeb::Controller::Trawl->set_timer;
        return;
      }

      # Run the trawler.
      TrawlWeb::Controller::Trawl->run_subprocess;
      return;
    }
  );
  return;
}

sub trawler_stats {
  return { start_time => Mojo::Date->new($runner_start_time)->to_datetime,
           last_run_duration => $runner_last_finish_duration,
           current_duration  => time() - $runner_start_time,
           run_count         => $run_count
         };
}

sub run_subprocess ($self) {

  # This is an extra safety for race conditions.
  if ($runner_running) {
    say STDERR "Runner was already running.";
    return;
  }
  $runner_running    = 1;
  $runner_start_time = time;
  $run_count += 1;

  return $subprocess->run_p(

    # The only thing we want to put inside of this sub
    # is stuff we that we want to live in the subprocess.
    # This function will run as a fork, and then
    # the thenable things (and the catch) will be joined
    # back within the parent process.
    sub {
      my $shutdown = 0;
      local $SIG{INT} = local $SIG{TERM} = sub {
        say STDERR
"$toplevel_pid => $$ SHUTTING DOWN TRAWLER!!!! Please do not interrupt further!";
        $shutdown = 1;
      };
      say STDERR "Running trawler...";
      my $org     = $ENV{GITHUB_USER_ORG};
      my $trawler = Trawler->new;

      $trawler->trawl_all($org, 1, sub { $shutdown });
    }
    )->then(
    sub {
      say STDERR "Trawler finished.";
      $runner_last_finish_duration = time() - $runner_start_time;
      $runner_start_time           = 0;
      $runner_running              = 0;

      # Set the timer to run again later.
      $self->set_timer;
    }
    )->catch(
    sub ($err) {

      # Reset stuff.
      $runner_last_finish_duration = time() - $runner_start_time;
      $runner_start_time           = -1;
      $runner_running              = 0;
      $self->set_timer;

      say STDERR Mojo::Date->new()->to_datetime
        . ": Error running the trawler: $err";
    }
    );
}

sub run ($self) {

  # Some useful stats!
  $self->stash(stats => $self->trawler_stats);

  # Don't do anything if it's already running.
  if ($runner_running) {
    return $self->stash(msg => "The trawler is already running.");
  }

  $self->stash(msg => "Starting trawler.");

  # Invalidate any caches we have.
  $self->org_member->invalidate_cache;

  return $self->run_subprocess;
}

# Start things off! (unless trawler is disabled.)
if (not exists $ENV{DISABLE_TRAWLER}) {
  TrawlWeb::Controller::Trawl->set_timer;
}

1;
