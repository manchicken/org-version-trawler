package PackageManager;

use Modern::Perl '2020';
use Readonly;
use Carp qw/confess/;

use PackageManager::RequirementsTxt;
use PackageManager::PipfileLock;
use PackageManager::PackageJson;
use PackageManager::Dockerfile;
use PackageManager::CfnLambdaRuntime;
use PackageManager::PomXml;

Readonly::Scalar my $managers => {
              PackageManager::RequirementsTxt->package_manager_details->{re} =>
                q?PackageManager::RequirementsTxt?,
              PackageManager::PipfileLock->package_manager_details->{re} =>
                q?PackageManager::PipfileLock?,
              PackageManager::PackageJson->package_manager_details->{re} =>
                q?PackageManager::PackageJson?,
              PackageManager::Dockerfile->package_manager_details->{re} =>
                q?PackageManager::Dockerfile?,
              PackageManager::CfnLambdaRuntime->package_manager_details->{re} =>
                q?PackageManager::CfnLambdaRuntime?,
              PackageManager::PomXml->package_manager_details->{re} =>
                q?PackageManager::PomXml?,
};

sub has_package_manager {
  my ($pkg, $path) = @_;

  return !!scalar grep { $path =~ m/$_/x } keys %{$managers};
}

sub load {
  my ($pkg, $git_tree_entry) = @_;

  return
    if (   not ref($git_tree_entry)
        or not exists $git_tree_entry->{path});

  my @potential_packages =
    grep { !!$_ && $git_tree_entry->{path} =~ m/$_/x } keys %{$managers};

  if (scalar @potential_packages > 1) {
    confess
"There are @potential_packages potential packages available for the file '$git_tree_entry->{path}'. Choosing the first, but this may not be correct.";
  } elsif (0 == scalar @potential_packages) {
    return;
  }

  return $managers->{ $potential_packages[0] }->new($git_tree_entry);
}

1;
