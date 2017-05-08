curl -v -XPUT \-H "Content-Type: application/json" \
-d@script/foo-bar.json \
http://127.0.0.1:9292/pacts/provider/Bar/consumer/Foo/version/1.0.0
