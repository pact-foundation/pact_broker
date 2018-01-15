#!/bin/sh
set -e
cd db/test/backwards_compatibility
rm -rf log
export BUNDLE_GEMFILE=$PWD/Gemfile
bundle install
bundle exec appraisal update
bundle exec appraisal install
set +e
bundle exec rake
rake_exit_code=$?
if [[ $rake_exit_code -ne 0 && -n "$TRAVIS" ]]; then
  cat log/pact_broker.log
fi
