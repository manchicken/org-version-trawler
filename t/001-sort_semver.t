#!/usr/bin/env perl

use Modern::Perl '2020';
use PackageManager::Util qw/sort_semver/;

use Test::More tests => 2;

{
  my $list1           = [qw/1.0.0 0.1.0 1.1.3 2.1.0 1.14.3 ^0.0.1/];
  my $correct         = [qw/^0.0.1 0.1.0 1.0.0 1.1.3 1.14.3 2.1.0/];
  my $correct_reverse = [qw/2.1.0 1.14.3 1.1.3 1.0.0 0.1.0 ^0.0.1/];

  is_deeply([ sort { sort_semver($a, $b) } @{$list1} ],
            $correct, 'Simple case.');
  is_deeply([ sort { sort_semver($b, $a) } @{$list1} ],
            $correct_reverse, 'Reverse simple case.');
};
