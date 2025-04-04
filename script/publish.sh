#!/usr/bin/env bash
function finish {
	rm -rf $tmpfile
}
trap finish EXIT

set -x

consumer_version="1.0.$(ruby -e "puts (rand * 10).to_i")"
consumer=${1:-Foo}
provider=${2:-Bar}
escaped_consumer=$(echo $consumer | ruby -e "require 'uri'; puts URI.encode(ARGF.read.strip)")
escaped_provider=$(echo $provider | ruby -e "require 'uri'; puts URI.encode(ARGF.read.strip)")
echo $consumer $provider

body=$(cat script/foo-bar.json | sed "s/Foo/${consumer}/" | sed "s/Bar/${provider}/")
tmpfile=$(mktemp)
echo $body >$tmpfile
curl -v -XPOST \-H "Content-Type: application/json" \
	-d@$tmpfile \
	http://127.0.0.1:9292/contracts/publish
echo ""
