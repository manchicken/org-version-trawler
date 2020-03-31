#!/usr/bin/env perl

use Modern::Perl '2020';

# This allows us to find our own libs which are shared by the Trawler.
use FindBin qw/$Bin/;
use lib qq{$Bin/../lib};

use Carp qw/cluck/;
use Data::Dumper;

use Trawler;

sub main {
  my $trawler = Trawler->new();
  $trawler->trawl_all;

  return 0;
}

exit main()
