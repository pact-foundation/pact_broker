#!/bin/sh
set -e
cd db/test/backwards_compatibility
export BUNDLE_GEMFILE="$(pwd)/Gemfile"
bundle install
bundle exec appraisal install
bundle exec rake db:spec
