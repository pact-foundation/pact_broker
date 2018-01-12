BASE_URL="http://localhost:9292"

response_body=$(curl ${BASE_URL}/pacts/provider/Bar/consumer/Foo/latest)
verification_url=$(echo "${response_body}" | ruby -e "require 'json'; puts JSON.parse(ARGF.read)['_links']['pb:publish-verification-results']['href']")
curl -XPOST -H 'Content-Type: application/json' -d@script/foo-bar-verification.json ${verification_url}
