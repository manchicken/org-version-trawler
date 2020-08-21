package PackageManager::PomXml;

use Modern::Perl '2020';
use Readonly;
use JSON;

## no critic (ProhibitSubroutinePrototypes)
use Mojo::Base 'Mojolicious::Controller', -signatures;

use XML::TreePP;
use Carp qw/cluck/;
use PackageManager::Util qw/get_semver_from_string/;

use Data::Dumper;

sub package_manager_details {
  return { name => 'Maven POM',
           re   => qr/^[a-z0-9_\/-]*?(\b|\d)pom(\b|\d)[a-z0-9_-]*?\.xml$/ix
         };
}

sub new ($pkg, $data) {
  my $self = { data => $data };

  return bless $self, $pkg;
}

sub parse($self) {

  # If some of this code looks super imperative and dated, that's because it is.
  # The Maven::Pom::Xml module was meant for a different task than we're
  # using it here, but it'll get the job done.

  $self->{deps} ||= [];

  # Don't bother if we don't have legit data.
  return if (not $self->{data} or not length $self->{data});

  my $success = eval {
    my $pom = XML::TreePP->new(utf8_flag => 1)->parse($self->{data}->content)
      ->{project};

    # Since there's a lot of variety in how these files are constructed,
    # We need to be a little flexible.
    my @paths  = qw/dependencyManagement dependencies dependency/;
    my $depref = $pom;
    while (my $next = shift @paths) {
      last if ref $depref eq 'ARRAY';
      ## NEW TO PERL?
      # In Perl you can have a reference to pretty much anything.
      # In this chunk I'm trying to traverse a nested structure having
      # a limited set of possible keys. In order to traverse, though, I
      # need to make sure that I'm going into a hashref (a reference to a hash).
      # Using `ref $foo eq 'HASH'` I can determine whether a scalar
      # contains a reference to a hash.
      ## END
      if (exists $depref->{$next}) {
        $depref = $depref->{$next};
      }
    }

    # At this point, $depref should point at an arrayref.
    if (ref $depref ne 'ARRAY') {
      say STDERR "I don't know how to parse this pom.xml.";
      return;
    }

    # Properties don't see so fluid as the dependencies structure.
    my $properties = $pom->{properties};

    # Now we're going to construct the internal dependency list.
    for my $raw_dep (@{$depref}) {
      my $name    = $raw_dep->{artifactId};
      my $version = exists $raw_dep->{version} ? $raw_dep->{version} : 'any';

      if (substr($version, 0, 2) eq q?${?) {
## It's common in a pom.xml to have the version be tokenized out into the properties
# section, so now we need to make sure that we parse through those if it's present.
# It's likely imperfect, but "good enough" is what we're going for.
        my $prop_token = substr($version, 2, rindex($version, '}') - 2);
        $version =
          exists $properties->{$prop_token}
          ? $properties->{$prop_token}
          : $version;
        if (ref $version eq 'ARRAY') {
          $version = join ' - ', @{$version};
        }
      }

      push @{ $self->{deps} }, { package => $name, version => $version };
    }

    return 1;
  };
  if (my $err = $@) {

    cluck "Error parsing file: $err";
  }
  if (!$success) {
    cluck "Failed to parse the file, not sure why. $@";
  }

  return;
}

sub has_dependencies($self) {

  # Lazy parse.
  $self->parse()
    if (not exists $self->{deps});

  return scalar @{ $self->{deps} } > 0;
}

sub next_dependency ($self) {

  # Lazy parse.
  $self->parse()
    if (not exists $self->{deps});

  return shift @{ $self->{deps} };
}

1;
