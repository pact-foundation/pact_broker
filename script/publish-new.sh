# set -x
BODY=$(ruby -e "require 'json'; j = JSON.parse(File.read('script/foo-bar.json')); j['interactions'][0]['providerState'] = 'it is ' + Time.now.to_s; puts j.to_json")
echo ${BODY} >> tmp.json
curl -v -XPUT \-H "Content-Type: application/json" \
-d@tmp.json \
http://127.0.0.1:9292/pacts/provider/Bar/consumer/Foo/version/1.0.0
rm tmp.json
