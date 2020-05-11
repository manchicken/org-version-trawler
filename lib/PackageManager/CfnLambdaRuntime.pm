package PackageManager::CfnLambdaRuntime;

use Modern::Perl '2020';
use Readonly;

use Data::Dumper;

Readonly my $runtime_matrix => {
                              'nodejs8.10' => [ 'NodeJS', '8.10 (DEPRECATED)' ],
                              'nodejs12.x' => [ 'NodeJS', '12' ],
                              'nodejs10.x' => [ 'NodeJS', '10' ],
                              'python3.8'  => [ 'Python', '3.8' ],
                              'python3.7'  => [ 'Python', '3.7' ],
                              'python3.6'  => [ 'Python', '3.6' ],
                              'python2.7'  => [ 'Python', '2.7' ],
};

sub package_manager_details {
  return {
    name => 'Lambda Runtime (CFN YAML)',

    # Look for any YAML file not named `*buildspec.ya?ml`
    re => qr/\/?.*?(?<!buildspec)\.ya?ml$/ix,
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
  $self->{content} = [ grep { $_ !~ m/^\s+?\#/xs } split(m/\r?\n/x, $text) ];

  return;
}

sub has_dependencies {
  my ($self) = @_;

  my $dep = $self->next_dependency;

  # Delete this so that it will be reparsed on the next `next_dependency` call.
  delete $self->{content};

  return !!$dep;
}

sub next_dependency {
  my ($self) = @_;

  $self->parse() if ('ARRAY' ne ref $self->{content});
  while (scalar @{ $self->{content} }) {
    my $line = shift @{ $self->{content} } || '';
    next if (index($line, ':') < 0);    # No colon, it couldn't be a match.
    if ($line =~ m/^\s*?Runtime\s*?:\s*(?<runtime>.*?)$/xs) {
      if (exists $runtime_matrix->{ $+{runtime} }) {
        my $runtime = $runtime_matrix->{ $+{runtime} };
        return { package => $runtime->[0], version => $runtime->[1] };
      }

      return { package => 'OTHER', version => $+{runtime} };
    }
  }

  return;
}

1;
