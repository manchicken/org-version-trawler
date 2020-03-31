package PackageManager::RequirementsTxt;

use Modern::Perl '2020';
use Readonly;

Readonly::Scalar my $operator_splitter => qr/[><=?]{2}/x;

use PackageManager::Util qw/get_semver_from_string/;

sub package_manager_details {
  return { name => 'pip',
           re   => qr/\/?.*?requirements.*?\.txt$/ix
         };
}

sub new {
  my ($pkg, $data) = @_;

  my $self = { data => $data, content => undef };

  return bless $self, $pkg;
}

sub parse {
  my ($self) = @_;

  my $text = $self->{data}->content;
  $self->{content} = [ grep { $_ !~ m/^\s+?#/xs } split(m/\r?\n/x, $text) ];

  return;
}

sub next_dependency {
  my ($self) = @_;

  # Lazy parse.
  $self->parse() if ('ARRAY' ne ref $self->{content});
  while (scalar @{ $self->{content} }) {
    my $line = shift @{ $self->{content} } || '';
    my ($package, $version) = split $operator_splitter, $line;
    if ($package and $version) {
      return { package => $package,
               version => get_semver_from_string($version)
             };
    }
  }

  return;
}

1;
