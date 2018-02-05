rm -rf tmp/pact_broker_database_test.sqlite3
RACK_ENV=test bundle exec rake db:migrate
