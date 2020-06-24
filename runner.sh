#!/bin/sh

if [ "$1" = "web" ]; then
  echo "Running web..."
  carton exec ./trawl_web/script/trawl_web daemon
elif [ "$1" = "trawler" ]; then
  echo "Running trawler..."
  BAD=""
  if [ -z "$GITHUB_ACCESS_TOKEN" ]; then
    echo "MISSING GITHUB_ACCESS_TOKEN IN ENVIRONMENT. SEE README.md"
    BAD="1"
  fi
  if [ -z "$GITHUB_USER_ORG" ]; then
    echo "MISSING GITHUB_USER_ORG IN ENVIRONMENT. SEE README.md"
    BAD="1"
  fi

  if [ -z "$BAD" ]; then
    carton exec perl ./bin/trawl.pl
  fi
fi