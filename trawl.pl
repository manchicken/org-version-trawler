#!/usr/bin/env perl

use Modern::Perl '2020';

use Data::Dumper;
use Git;
use Part::Persistence;

sub main {
  my $git = Git->new();
  $git->init;

  my $tree = $git->get_tree_for_next_repo;
  my $next_item = $tree->next(
    sub {
      my ($item) = @_;

      return 1
        if (    $item->{type} eq 'blob'
            and $item->{path} =~ m/^.*?requirements.*?\.txt$/ix);
    }
  );
  say Dumper("CONTENT", $next_item->{path}, $next_item->content);

  return 0;
}

exit main()
