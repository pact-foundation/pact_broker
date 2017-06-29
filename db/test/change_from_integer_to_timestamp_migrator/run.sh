#!/bin/sh
set -e

# Do migrations with pact_broker gem version that uses integer migrations
rm -rf before/Gemfile.lock
rm -rf pact_broker_database.sqlite3
bundle install --gemfile before/Gemfile
export BUNDLE_GEMFILE=before/Gemfile
bundle exec rake pact_broker:db:migrate[35]
bundle exec rake pact_broker:db:version
bundle exec ruby insert_test_data.rb

# Do migrations with pact_broker gem version that uses timestamp migrations
bundle install --gemfile after/Gemfile
export BUNDLE_GEMFILE=after/Gemfile
bundle exec rake pact_broker:db:migrate
bundle exec rake pact_broker:db:version
bundle exec ruby check_schema_migrations_table.rb

# Try rolling back
bundle exec rake pact_broker:db:migrate[34]
bundle exec rake pact_broker:db:version
