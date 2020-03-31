package PackageManager::PipfileLock;

use Modern::Perl '2020';
use Readonly;
use JSON;

use PackageManager::Util qw/get_semver_from_string/;

sub package_manager_details {
  return { name => 'pipenv',
           re   => qr/\/?.*?Pipfile.*?\.lock$/ix
         };
}

sub new {
  my ($pkg, $data) = @_;

  my $self = { data => $data };

  return bless $self, $pkg;
}

sub parse {
  my ($self) = @_;

  my $obj = decode_json($self->{data}->content);
  $self->{deps} = [];

  # Python version
  if (exists $obj->{_meta}->{requires}->{python_version}) {
    push @{ $self->{deps} },
      { package => 'python_version',
        version =>
          get_semver_from_string($obj->{_meta}->{requires}->{python_version})
      };
  }

  # Other dependencies
  if (exists $obj->{default}) {
    for my $dep_name (keys %{ $obj->{default} }) {
      next if not exists $obj->{default}->{$dep_name}->{version};

      push @{ $self->{deps} },
        { package => $dep_name,
          version =>
            get_semver_from_string($obj->{default}->{$dep_name}->{version})
        };
    }
  }

  return;
}

sub next_dependency {
  my ($self) = @_;

  # Lazy parse.
  $self->parse()
    if (not exists $self->{deps});

  return shift @{ $self->{deps} };
}

1;
