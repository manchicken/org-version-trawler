# org-version-trawler

## Configuring your Perl environment

- Install Perl 5.30 or greater.
- Install `App::cpanminus`
- Install `Carton`
- Run `carton install`
- Make sure that your `PERL5LIB` environment has `.:./lib` as the first two entries.

## Environment Variables

- `GITHUB_ACCESS_TOKEN` - This is your Github access token. Be careful with how you store this.
- `GITHUB_USER_ORG` - This is the username or organization name that you want to trawl. If you don't have permissions to the repository, the trawler will error out.
- `TRAWLER_DATA_DIR` - This should point at the directory where you want data to live. If this value is missing, it will default to `$PWD/data`.

## Running

There are two programs in this package:

1. The trawler
2. The web app

The web app uses data produced by the trawler, so run that first. It will take a _long_ time (hours, not days) as it trawls through all of the repositories. Github rate-limits things, this definitely slows things down.

**Note:** If the trawler is interrupted, simply restart it. It will start all over again, but it won't hurt anything.

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

- Add the ability to trigger a repository for trawling from within the web app.
- Java Maven `pom.xml` file support (most important!).
- Allow for the database to be uploaded to S3, or otherwise solve the problem where the DB doesn't survive the container.

## AUTHOR

- Mike Stemle, Jr. <themanchicken@gmail.com> (original author, maintainer)