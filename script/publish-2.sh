curl -v -XPUT \-H "Content-Type: application/json" \
	-d@spec/fixtures/a_consumer-a_provider-2.json \
	http://localhost:9292/pacts/provider/A%20Provider/consumer/A%20Consumer/version/1.0.1
echo ""
