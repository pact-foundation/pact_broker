#!/usr/bin/env bash

PACT_BROKER_TEST_DATABASE_URL=postgres://postgres:postgres@localhost/postgres bundle exec rake pact_broker:db:migrate
