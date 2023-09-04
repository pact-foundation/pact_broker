#!/bin/bash

# Add these arguments to deliberately slow down the database when working on performance issues
#
# --cpu-period=100000 --cpu-quota=50000 \
#
docker run --name pact-broker-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -v $PWD:/data \
  -d postgres:14
