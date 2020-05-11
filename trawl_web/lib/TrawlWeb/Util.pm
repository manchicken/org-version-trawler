package TrawlWeb::Util;

use Modern::Perl '2020';

use Readonly;
use base q{Exporter};
Readonly our @EXPORT_OK => qw{ min_height unfixname };

sub min_height {
  my ($x) = @_;
  return $x > 500 ? $x : 500;
}

sub unfixname {
  my ($name) = @_;

  $name =~ s/_SLASH_/\//xg;
  $name =~ s/_DOT_/\./xg;

  return $name;
}

1;
