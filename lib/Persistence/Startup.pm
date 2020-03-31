package Persistence::Startup;

use Modern::Perl '2020';

use Mojo::SQLite::Migrations;

sub startup {
  my ($pkg, $db) = @_;

  my $migration = Mojo::SQLite::Migrations->new(sqlite => $db);
  $migration->from_data->migrate;

  return;
}

1;

__DATA__

@@migrations

-- 1 up

create table repository (
  name TEXT NOT NULL,
  org TEXT NOT NULL,
  sha TEXT NOT NULL
);
create index idx_repo_name on repository (name);
create unique index idx_repo_name_org on repository (name, org);

create table dependency_file (
  repository INTEGER NOT NULL,
  path TEXT NOT NULL,
  package_manager TEXT NOT NULL
);
create unique index idx_dependency_file on dependency_file (repository, path);

create table dependency_version (
  package_manager TEXT,
  package_name TEXT,
  version_string TEXT
);

create table repository_dependency (
  repository INTEGER,
  dependency_file INTEGER,
  dependency_version INTEGER,
  noticed DATETIME DEFAULT CURRENT_TIMESTAMP
);
create index idx_rd_repository on repository_dependency (repository);
create index idx_rd_dependency_version on repository_dependency (dependency_version);

-- 1 down
drop table repository;
drop table dependency_file;
drop table dependency_version;
drop table repository_dependency;
