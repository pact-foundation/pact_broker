#!/bin/bash

docker run \
  --name pact-broker-mysql \
  -e MYSQL_ROOT_PASSWORD=pact_broker \
  -e MYSQL_USER=pact_broker \
  -e MYSQL_PASSWORD=pact_broker \
  -e MYSQL_DATABASE=pact_broker \
  -p 3306:3306 \
  -d mysql:5.7.27
