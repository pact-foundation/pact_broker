#!/bin/bash
#
# Usage: migrate-latest-pacts.sh SOURCE_BROKER_BASE_URL DEST_BROKER_BASE_URL
#

set -e

function cleanup() {
  rm -rf /tmp/pact
}

trap cleanup EXIT

source_broker_base_url=${1:?Usage: ${BASH_SOURCE[0]} SOURCE_BROKER_BASE_URL DEST_BROKER_BASE_URL}
dest_broker_base_url=${2:?Usage: ${BASH_SOURCE[0]} SOURCE_BROKER_BASE_URL DEST_BROKER_BASE_URL}

latest_pacts=$(curl -s ${source_broker_base_url}/pacts/latest)
latest_pact_urls=$(echo "${latest_pacts}" | jq "[.pacts[]._links.self[1:][].href]" | jq 'join("\n")' --raw-output)

for url in ${latest_pact_urls}
do
  source_pact_content=$(curl -s $url)
  source_pact_url=$(echo ${source_pact_content} | jq "._links.self.href" --raw-output)
  dest_pact_url=$(echo "${source_pact_url}" | sed "s~${source_broker_base_url}~${dest_broker_base_url}~")
  dest_pact_content=$(echo "${source_pact_content}" | jq -r '{consumer: .consumer, provider: .provider, interactions: .interactions, metadata: .metadata}')
  echo "${source_pact_content}" > /tmp/pact
  echo "Migrating ${source_pact_url} to ${dest_pact_url}"
  curl -s -XPUT "${dest_pact_url}" -d @/tmp/pact -H "Content-Type: application/json" -H "Accept: application/hal+json" > /dev/null
done
