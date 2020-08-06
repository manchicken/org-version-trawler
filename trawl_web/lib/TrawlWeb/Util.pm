package TrawlWeb::Util;

use Modern::Perl '2020';
use Mojo::Util qw/url_escape url_unescape/;

use Readonly;
use base q{Exporter};
Readonly our @EXPORT_OK => qw{ min_height };

sub min_height {
  my ($x) = @_;
  return $x > 500 ? $x : 500;
}

1;
