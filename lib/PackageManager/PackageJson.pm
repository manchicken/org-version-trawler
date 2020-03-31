package PackageManager::PackageJson;

use Modern::Perl '2020';
use Readonly;
use JSON;

use Syntax::Keyword::Try;
use PackageManager::Util qw/get_semver_from_string/;

sub package_manager_details {
  return { name => 'npm|yarn',
           re   => qr/(^|\/)package\.json$/ix
         };
}

sub new {
  my ($pkg, $data) = @_;

  my $self = { data => $data };

  return bless $self, $pkg;
}

sub parse {
  my ($self) = @_;

  my $obj = undef;
  $self->{deps} = [];
  try {
    $obj = decode_json($self->{data}->content);

    $self->extract_deps($obj, 'dependencies');
    $self->extract_deps($obj, 'devDependencies');
    $self->extract_deps($obj, 'peerDependencies');
    $self->extract_deps($obj, 'optionalDependencies');
  } catch {
    my ($err) = @_;

    say "Error parsing file: $err";
  };

  return;
}

sub extract_deps {
  my ($self, $obj, $dep_type) = @_;

  # Other dependencies
  if (exists $obj->{$dep_type}) {
    for my $dep_name (keys %{ $obj->{$dep_type} }) {
      next if not exists $obj->{$dep_type}->{$dep_name};

      push @{ $self->{deps} },
        { package => $dep_name,
          version => get_semver_from_string($obj->{$dep_type}->{$dep_name}),
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
