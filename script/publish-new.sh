set -e
BODY=$(ruby -e "require 'json'; j = JSON.parse(File.read('script/foo-bar.json')); j['interactions'][0]['providerState'] = 'it is ' + Time.now.to_s; puts j.to_json")
latest_url=$(curl http://localhost:9292/pacts/provider/Bar/consumer/Foo/latest | jq -r ._links.self.href)
next_version=$(echo ${latest_url} | ruby -e "version = ARGF.read[/\d+\.\d+\.\d+/]; require 'semver'; puts SemVer.parse(version).tap{ | v| v.minor = v.minor + 1}.format('%M.%m.%p')")
echo ${BODY} > tmp.json
curl -v -XPUT \-H "Content-Type: application/json" -d@tmp.json \
  http://localhost:9292/pacts/provider/Bar/consumer/Foo/version/${next_version}
rm tmp.json
echo ""
