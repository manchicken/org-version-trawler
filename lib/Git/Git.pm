package Git;

use Modern::Perl '2020';

use Net::GitHub::V3;
use Data::Dumper;

use Git::Tree;

sub new {
  my ($pkg) = @_;

  return bless {}, $pkg;
}

sub init {
  my ($self) = @_;

  # GraphQL APIs
  # $self->{gh_4} =
  # Net::GitHub::V4->new(access_token => $ENV{GITHUB_ACCESS_TOKEN});

  # REST APIs
  $self->{gh_3} =
    Net::GitHub::V3->new(access_token => $ENV{GITHUB_ACCESS_TOKEN});

  return $self;
}

# Fetch a page of repositories.
sub next_repository {
  my ($self, $opts) = @_;

  my $org = exists $opts->{org} ? $opts->{org} : 'WPMedia';

  return $self->gh->repos->next_org_repo($org);
}

sub gh {
  my ($self) = @_;
  return exists $self->{gh_3} ? $self->{gh_3} : $self->init->{gh_3};
}

sub get_tree_for_next_repo {
  my ($self) = @_;

  # Get the repo
  my $repo_deets = $self->next_repository;
  return
       if !ref $repo_deets
    or !exists $repo_deets->{owner}->{login}
    or !exists $repo_deets->{name};

  # Set the user and the repo
  $self->gh->set_default_user_repo($repo_deets->{owner}->{login},
                                   $repo_deets->{name});

  # Get the most recent commit
  my $commit = $self->gh->repos->next_commit;
  return if !ref $commit or !exists $commit->{commit}->{tree};

  my $tree = $self->gh->git_data->trees($commit->{commit}->{tree}->{sha});

  # Return the tree.
  return Git::Tree->new({ %$tree, gh => $self->gh });
}

1;
