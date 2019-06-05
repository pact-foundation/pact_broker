#!/bin/bash

docker run --name pact-broker-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -v $PWD:/data \
  -d postgres:10
