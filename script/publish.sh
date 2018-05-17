#!/bin/sh
function finish {
  rm -rf tmp/pact.json
}
trap finish EXIT

set -x

consumer=${1:-Foo}
provider=${2:-Bar}
escaped_consumer=$(echo $consumer | ruby -e "require 'uri'; puts URI.encode(ARGF.read.strip)")
escaped_provider=$(echo $provider | ruby -e "require 'uri'; puts URI.encode(ARGF.read.strip)")
echo $consumer $provider
body=$(cat script/foo-bar.json | sed "s/Foo/${consumer}/" | sed "s/Bar/${provider}/")
echo $body > tmp/pact.json
curl -v -XPUT \-H "Content-Type: application/json" \
-d@tmp/pact.json \
http://127.0.0.1:9292/pacts/provider/${escaped_provider}/consumer/${escaped_consumer}/version/1.0.0
echo ""
