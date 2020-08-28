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
  sha TEXT NOT NULL,
  archived CHAR(1) NOT NULL,
  empty CHAR(1) NOT NULL,
  last_commit DATETIME NULL,
  last_committed_by TEXT NULL
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

create table org_member (
  login TEXT NOT NULL,
  type TEXT NOT NULL,
  avatar_url TEXT NULL,
  last_seen DATETIME NOT NULL,
  assumed_active CHAR
);
create index idx_om_login on org_member (login);

create table repository_contributor (
  repository INTEGER,
  login TEXT NOT NULL,
  avatar_url TEXT NULL,
  type TEXT NOT NULL,
  contributions INT NOT NULL DEFAULT 0
);

-- 1 down
drop table repository;
drop table dependency_file;
drop table dependency_version;
drop table repository_dependency;
