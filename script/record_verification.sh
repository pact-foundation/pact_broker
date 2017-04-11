curl -v -XPOST \-H "Content-Type: application/json" \
-d@spec/fixtures/record_verification.json \
http://127.0.0.1:9292/pacts/provider/Animal%20Service/consumer/Zoo%20App/version/1.0.2/verifications
