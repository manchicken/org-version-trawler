package Git;

## no critic (ProhibitSubroutinePrototypes)
use Mojo::Base -signatures;
use utf8;

use Carp qw/croak cluck/;
use Syntax::Keyword::Try;
use Net::GitHub::V3;
use Data::Dumper;

use Git::Tree;

sub new {
  my ($pkg) = @_;

  return bless {}, $pkg;
}

sub init {
  my ($self) = @_;

  # REST APIs
  $self->{gh_3} =
    Net::GitHub::V3->new(access_token => $ENV{GITHUB_ACCESS_TOKEN});

  return $self;
}

# Fetch a page of repositories.
sub next_repository {
  my ($self, $opts) = @_;

  my $org = exists $opts->{org} ? $opts->{org} : $ENV{GITHUB_USER_ORG};

  if (!$org) {
    croak "No org defined. Please set \$GITHUB_USER_ORG in your environment.";
  }

  return $self->gh->repos->next_org_repo($org);
}

sub gh {
  my ($self) = @_;
  return exists $self->{gh_3} ? $self->{gh_3} : $self->init->{gh_3};
}

sub get_tree_for_next_repo {
  my ($self, $ctx) = @_;

  # Get the next repo, keeping in mind we may have to skip a few.
  while (my $repo_deets = $self->next_repository) {

    if (   not ref $repo_deets
        or not exists $repo_deets->{owner}->{login}
        or not exists $repo_deets->{name})
    {
      say "ACK! FAILED TO GET NEXT REPO!";
      return;
    }

    my $tree = $self->get_tree_for_repo($repo_deets->{owner}->{login},
                                        $repo_deets->{name});
    next if !$tree;

    $tree->{repo}->{archived} = $repo_deets->{archived} ? 'T' : 'F';

    return $tree;
  }

  return;
}

sub get_contributors_for_repo ($self, $user, $repo) {
  my $contributors = undef;

  try { $contributors = $self->gh->repos->contributors($user, $repo); }
  catch {
    my ($err) = @_;
    cluck "Failed to get contributors for repo $user/$repo: $err";
  };

  return $contributors;
}

sub get_tree_for_repo ($self, $user, $repo) {

  # Set the user and the repo
  $self->gh->set_default_user_repo($user, $repo);

  # Get the most recent commit
  my $commit = undef;
  try { $commit = $self->gh->repos->next_commit; }
  catch {
    my ($err) = @_;
    cluck "Failed to get latest commit for repo $user/$repo: $err";
    return;
  };

  # If we didn't get an exception...
  if (not exists $commit->{commit}->{tree}->{sha}) {
    cluck "There is no tree for repo $user/$repo";
    return;
  }

  my $tree = undef;

  try { $tree = $self->gh->git_data->trees($commit->{commit}->{tree}->{sha}); }
  catch {
    my ($err) = @_;
    say STDERR Dumper($commit);
    cluck "Failed to get tree for repo $user/$repo: $err";
    return;
  };

  # Return the tree.
  return Git::Tree->new(
    {
      repo => {
        user     => $user,
        name     => $repo,
        sha      => $commit->{sha},
        metadata => {
          empty => defined $commit
          ? 'F'
          : 'T',    # If there's no commit, the repo is empty.
          last_commit       => $commit->{commit}->{committer}->{date} || undef,
          last_committed_by => $commit->{author}->{login}
                    }
              },
      %$tree,
      gh => $self->gh
    }
  );
}

1;
