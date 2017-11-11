BASE_URL="http://localhost:9292"

# delete pacticipants
curl -XDELETE ${BASE_URL}/pacticipants/Foo
curl -XDELETE ${BASE_URL}/pacticipants/Bar

# create pact 0.0.0 revision 1
response_body=$(curl -XPUT -H 'Content-Type: application/json' -d@script/foo-bar.json ${BASE_URL}/pacts/provider/Bar/consumer/Foo/version/0.0.0)

# verify pact 0.0.0 revision 1
verification_url=$(echo "${response_body}" | ruby -e "require 'json'; puts JSON.parse(ARGF.read)['_links']['pb:publish-verification-results']['href']")
curl -XPOST -H 'Content-Type: application/json' -d '{"success": true, "providerApplicationVersion": "0.0.0"}' ${verification_url}

# create pact 0.0.0 revision 2
response_body=$(curl -XPUT -H 'Content-Type: application/json' -d@script/foo-bar-2.json ${BASE_URL}/pacts/provider/Bar/consumer/Foo/version/0.0.0)

# verify pact 0.0.0 revision 2
verification_url=$(echo "${response_body}" | ruby -e "require 'json'; puts JSON.parse(ARGF.read)['_links']['pb:publish-verification-results']['href']")
curl -XPOST -H 'Content-Type: application/json' -d '{"success": true, "providerApplicationVersion": "0.0.0"}' ${verification_url}

# output the revision and verification history
echo ''
echo ''
curl -g -H 'Accept: text/plain' "http://localhost:9292/matrix?q[]pacticipant=Foo&q[]pacticipant=Bar"
