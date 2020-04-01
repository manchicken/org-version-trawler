package PackageManager::Util;

use Modern::Perl '2020';

use Readonly;
use base q{Exporter};

Readonly my $SEMVER_SELECTION_OPERATORS => qr/[~^><=+-]+/xms;
Readonly my $SEMVER_RE =>
  qr/(?<semver>(\d+|\d+\.\d+|\d+\.\d+\.\d+)(-[a-z]+)?)/xms;
Readonly my $SEMANTIC_VERSION_RE => qr/
    \A # Beginning of string
    $SEMVER_SELECTION_OPERATORS? # The operators indicating how versions should be selected.
    \s*                          # Some package managers allow for whitespace here.
    $SEMVER_RE                   # Named capture for the full version.
    \Z # End of string
  /xms;

Readonly our @EXPORT_OK => qw{
  $SEMANTIC_VERSION_RE
  get_semver_from_string
  sort_semver
  };

sub get_semver_from_string {
  my ($str) = @_;

  if ($str =~ $SEMANTIC_VERSION_RE) {
    return $+{semver};
  }

  return $str;
}

sub sort_semver {
  my ($a, $b) = @_;

  # In case these aren't semantic versions...
  if ($a !~ $SEMANTIC_VERSION_RE or $b !~ $SEMANTIC_VERSION_RE) {
    return $a cmp $b;
  }

  my $get_vers_list = sub {
    my ($str) = @_;
    my ($nums, $mods) = split /-/x, $str, 2;
    my ($major, $minor, $patch) = split /\./x, $nums, 3;
    $major = (not defined $major or $major eq '') ? 0 : int($major);
    $minor = (not defined $minor or $minor eq '') ? 0 : int($minor);
    $patch = (not defined $patch or $patch eq '') ? 0 : int($patch);

    return ($major, $minor, $patch, $mods || undef);
  };

  my @a_vers = $get_vers_list->($a);
  my @b_vers = $get_vers_list->($b);

  for my $vers_idx (0 .. 2) {
    if ($a_vers[$vers_idx] != $b_vers[$vers_idx]) {

      # Descending sort!
      return $b_vers[$vers_idx] - $a_vers[$vers_idx];
    }
  }

  # Eventually, maybe the version suffixes matter, but for now they don't.
  return 0;
}

1;
