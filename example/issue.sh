#!/bin/bash

cd example
rm -rf pact_broker_database.sqlite3
# bundle install
bundle exec rackup -p 9292 &
pid=$!

sleep 5

curl -X PUT \-H "Content-Type: application/json" -s -d@pact-1.json \
  http://localhost:9292/pacts/provider/Bar/consumer/Foo/version/123

echo && sleep 1

curl -X PUT \-H "Content-Type: application/json" -s -d@pact-2.json \
  http://localhost:9292/pacts/provider/Bar/consumer/Foo/version/122

echo && sleep 1

curl -X PUT \-H "Content-Type: application/json" -s -d@pact-3.json \
  http://localhost:9292/pacts/provider/Bar/consumer/Foo/version/2

echo && sleep 1
echo

echo 'Fetching latest version of pact'
curl http://localhost:9292/pacts/provider/Bar/consumer/Foo/latest -s | ruby -e "require 'json'; puts JSON.parse(ARGF.read)['_links']['pb:consumer-version']"
echo

echo 'Fetching matrix'
curl "http://localhost:9292/matrix?q%5B%5Dpacticipant=Foo&q%5B%5Dpacticipant=Bar" -g -H "Accept: text/plain" -s | grep "|"

kill $pid

sleep 5
