package TrawlWeb::Util;

## no critic (ProhibitSubroutinePrototypes)
use Mojo::Base -signatures;
use Mojo::Util qw/url_escape url_unescape/;

use Mojo::Date;
use DateTime;
use DateTime::Format::Strptime;
use Readonly;
use base q{Exporter};
Readonly our @EXPORT_OK => qw{ min_height present_date_from_date };

sub min_height {
  my ($x) = @_;
  return $x > 500 ? $x : 500;
}

# Re-format the date to the chosen timezone.
sub present_date_from_date {
  my ($date) = @_;

  my $locale = 'en_US';    # Needs to be made into an env var.

  my $time_zone = $ENV{TZ} || 'UTC';
  my $formatter =
    DateTime::Format::Strptime->new(locale    => $locale,
                                    time_zone => $time_zone,
                                    pattern   => '%F %R %Z',
                                   );
  return
    DateTime->from_epoch(formatter => $formatter,
                         time_zone => $time_zone,
                         epoch     => Mojo::Date->new($date)->epoch
                        )->stringify;
}

1;
