package PackageManager::Dockerfile;

use Modern::Perl '2020';
use Readonly;

use PackageManager::Util qw/get_semver_from_string/;

sub package_manager_details {
  return { name => 'Docker',
           re   => qr/\/?.*?Dockerfile$/ix
         };
}

sub new {
  my ($pkg, $data) = @_;

  my $self = { data => $data };

  return bless $self, $pkg;
}

sub parse {
  my ($self) = @_;

  my $text = $self->{data}->content;
  $self->{deps} = [];

  if ($text =~
     m/^\s*?FROM\s+(?<fromstr>.*?)\s*?$/mx) ## no critic (ProhibitUnusedCapture)
  {
    my @from = split m/:/x, $+{fromstr}, 2;

    # We're making this an arrayref to maintain consistency.
    push @{ $self->{deps} },
      { package => $from[0],
        version => $from[1] || 'UNTAGGED',
      };
  } else {
    say STDERR
      "NO FROM?!\n---------START--------\n${text}\n-----------END----------";
  }

  return;
}

sub has_dependencies {
  my ($self) = @_;

  # Lazy parse.
  $self->parse() if (not exists $self->{deps});

  return scalar @{ $self->{deps} } > 0;
}

sub next_dependency {
  my ($self) = @_;

  # Lazy parse.
  $self->parse() if (not exists $self->{deps});

  # Return deps if we have them.
  return shift @{ $self->{deps} };
}

1;
