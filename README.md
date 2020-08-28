# org-version-trawler

## Recommended Method for Running

This program is most commonly run inside of Docker. To run this, download it and then run it. It will automatically bind to port 3000 within the container and run.

**Docker Image:** https://hub.docker.com/repository/docker/washpost/org-version-trawler

Fun facts about this program:

- This program is read-only. There are no users and there's no way to add data.
- This program is _not_ intended to be run on the internet. Matter of fact, this is strongly discouraged as you may not like people knowing which vulnerable versions things are using.
- This program persists its data within a SQLite3 database housed inside the container itself.
  - This means that if your database gets corrupted, just delete and re-create the container.
  - This means you don't have to worry about upgrading your database when new versions are created.
  - If the container is destroyed, you'll have to wait for the trawler to run again.
- Do not run this app in multiple containers. This app is an island unto itself. Running multiple containers will likely result in inconsistent results.

## Environment Variables

- `GITHUB_ACCESS_TOKEN` - This is your Github access token. Be careful with how you store this.
- `GITHUB_USER_ORG` - This is the username or organization name that you want to trawl. If you don't have permissions to the repository, the trawler will error out.
- `TRAWLER_DATA_DIR` - This should point at the directory where you want data to live. If this value is missing, it will default to `$PWD/data`.
- `TZ` - This is the standardized IANA time zone name ([see more](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones))

## Running Outside of Docker

It is recommended that you only do this for development purposes.

### Configuring your Perl environment

- Install Perl 5.30 or greater.
- Install `App::cpanminus`
- Install `Carton`
- Run `carton install`
- Make sure that your `PERL5LIB` environment has `.:./lib` as the first two entries.

### Running

Before running anything, be sure to set the environment variables listed above.

There are two programs in this package:

1. The trawler (will also run by default within the web app)
2. The web app

**Note:** If the trawler is interrupted, simply restart it. It will start all over again, but it won't hurt anything. There is some support for incremental updates.

If your GitHub organization has a lot of repositories, it could take a very long time to run. GitHub rate-limits API calls, so it's important to be patient or you could end up locking your account out for a little while.

```sh
carton exec perl ./bin/trawl.pl
```

**NOTE**: It is not necessary to run the trawler separately. The trawler will run automatically along-side the web server.

To start with VS Code, use "Tasks: Run Task," and then "Run trawl_web".

To start with the command-line, run the following.

```sh
./runner.sh
```

This will automatically start the trawler in a subprocess of the web process. If you would prefer _not_ to run the trawler, set the `DEBUG` env variable to `2`.

```sh
DEBUG=2 ./runner.sh
```

Using `DEBUG=2` will not only disable the trawler, but it'll also have `morbo` watch all of the directories involved so that when you make UI changes it automatically updates.

## TODO

- Allow for the database to be uploaded to S3, or otherwise solve the problem where the DB doesn't survive the container.
- Presently, if you're developing and you change a code file while the web app is running the trawler, it will start up a new instance of the trawler. This should likely be fixed at some point.
- More testing. So much more testing.
- Need more ways of identifying unmaintained repositories.

## AUTHOR

- Mike Stemle, Jr. <themanchicken@gmail.com> (original author, maintainer)