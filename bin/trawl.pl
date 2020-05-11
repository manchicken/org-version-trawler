#!/usr/bin/env perl

use Modern::Perl '2020';

# This allows us to find our own libs which are shared by the Trawler.
use FindBin qw/$Bin/;
use lib qq{$Bin/../lib};

use Getopt::Long;
use Carp qw/cluck/;
use Data::Dumper;

use Trawler;

sub parse_args {
  my $args = {};

  GetOptions($args, 'repo=s@', 'all', 'org=s');
  return $args;
}

sub main {
  my $args    = parse_args();
  my $trawler = Trawler->new;
  my $org     = exists $args->{org} ? $args->{org} : $ENV{GITHUB_USER_ORG};

  say Dumper({ args => $args });

  if (exists $args->{all}) {
    $trawler->trawl_all($org);
  } elsif (scalar @{ $args->{repo} } > 0) {
    for my $repo (@{ $args->{repo} }) {
      $trawler->trawl_one($org, $repo);
    }
  }

  return 0;
}

exit main();
