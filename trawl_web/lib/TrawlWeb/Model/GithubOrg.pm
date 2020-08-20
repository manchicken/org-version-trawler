package TrawlWeb::Model::GithubOrg;

## no critic (ProhibitSubroutinePrototypes)
use Mojo::Base q{TrawlWeb::Model}, -signatures;
use Mojo::Exception qw/raise/;

use Readonly;

use Git;

has 'gh' => Git->new->init->gh;

sub find($self, $org_name=undef) {
  return $self->gh->org(
    $org_name || $ENV{GITHUB_USER_ORG} || q{};
  );
}

sub has_users($self, @users) {

}

1;
