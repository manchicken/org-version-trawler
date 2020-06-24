package PackageManager::RequirementsTxt;

use Modern::Perl '2020';

# SIGNATURES BOILERPLATE
## no critic (ProhibitSubroutinePrototypes)
use feature qw(signatures);
no warnings qw(experimental::signatures);    ## no critic (ProhibitNoWarnings)

# END SIGNATURES BOILERPLATE

use Readonly;

Readonly::Scalar my $operator_splitter => qr/[><=?]{2}/x;

use PackageManager::Util qw/get_semver_from_string/;

sub package_manager_details {
  return { name => 'pip',
           re   => qr/\/?.*?requirements.*?\.txt$/ix
         };
}

sub new ($pkg, $data) {
  my $self = { data => $data, content => undef };

  return bless $self, $pkg;
}

sub parse ($self) {
  my $text = $self->{data}->content;
  $self->{content} = [ grep { $_ !~ m/^\s+?\#/xs } split(m/\r?\n/x, $text) ];

  return;
}

sub has_dependencies ($self) {

  # Lazy parse.
  $self->parse() if ('ARRAY' ne ref $self->{content});

  return scalar @{ $self->{content} } > 0;
}

sub next_dependency ($self) {

  # Lazy parse.
  $self->parse() if ('ARRAY' ne ref $self->{content});
  while (scalar @{ $self->{content} }) {
    my $line = shift @{ $self->{content} } || '';
    my ($package, $version) = split $operator_splitter, $line;

    # Pull comments out of version numbers.
    if ($version and index($version, '#') > 0) {
      $version =~ s/\#.*$//xs;
    }

    # Trim leading and trailing white space.
    $version =~ s/\A\s+?(.*?)\s+?\Z/$1/sx if $version;

    if ($package and $version) {
      return { package => $package,
               version => get_semver_from_string($version)
             };
    }
  }

  return;
}

1;
