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

Once the trawler has finished, you can start the web-app to start digging in to the data. This can either be started on the command-line, or from within VS Code.

To start with VS Code, use "Tasks: Run Task," and then "Run trawl_web".

To start with the command-line, run the following.

```sh
carton exec morbo ./trawl_web/script/trawl_web
```

## TODO

- Add incremental support for trawlers, so that we can skip the repos which have already been trawled at their current commit.
- Add the ability to trigger a repository for trawling from within the web app.
- Java Maven `pom.xml` file support (most important!).
- Deploy into AWS infrastructure somewhere.
