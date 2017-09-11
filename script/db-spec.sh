#!/bin/sh
set -e
cd db/test/backwards_compatibility
bundle install
bundle exec appraisal install
bundle exec rake db:spec
