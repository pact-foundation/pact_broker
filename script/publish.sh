#!/bin/sh
function finish {
  rm -rf tmp/pact.json
}
trap finish EXIT

consumer=${1:-Foo}
provider=${2:-Bar}
echo $consumer $provider
body=$(cat script/foo-bar.json | sed "s/Foo/${consumer}/" | sed "s/Bar/${provider}/")
echo $body > tmp/pact.json
curl -v -XPUT \-H "Content-Type: application/json" \
-d@tmp/pact.json \
http://127.0.0.1:9292/pacts/provider/${provider}/consumer/${consumer}/version/1.0.0
echo ""
