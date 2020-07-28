#!/bin/sh

if [ -z "$GITHUB_ACCESS_TOKEN" ]; then
  echo "MISSING GITHUB_ACCESS_TOKEN IN ENVIRONMENT. SEE README.md"
  BAD="1"
fi
if [ -z "$GITHUB_USER_ORG" ]; then
  echo "MISSING GITHUB_USER_ORG IN ENVIRONMENT. SEE README.md"
  BAD="1"
fi

DEBUG_ARGS="-m production"
if [ "$DEBUG" = "1" ]; then
  DEBUG_ARGS="-m development"
elif [ "$DEBUG" = "2" ]; then
  DEBUG_ARGS="-m development -w lib -w trawl_web"
  export DISABLE_TRAWLER="1"
fi

if [ -z "$BAD" ]; then
  echo "Running web..."
  carton exec morbo ./trawl_web/script/trawl_web $DEBUG_ARGS
else
  echo "There was an environment problem detected. Aborting run."
fi