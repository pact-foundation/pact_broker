#!/bin/sh

# fill in appropriate values for the database credentials

export PGUSER=""
export PGPASSWORD=""
export PGHOST=""
export PGDATABASE=""

pg_dump --no-acl --no-owner --file pact_broker.dump
