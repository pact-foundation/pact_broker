RSpec.describe "the pending pacts flow" do
  let(:pact_content_1) { { some: "interactions" }.to_json }
  let(:pact_content_2) { { some: "other interactions" }.to_json }
  let(:request_headers) { { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/hal+json"} }
  let(:failed_verification_results) do
    {
      providerApplicationVersion: "2",
      success: false
    }.to_json
  end
  let(:successful_verification_results) do
    {
      providerApplicationVersion: "2",
      success: true
    }.to_json
  end

  context "with no tags" do
    it "is pending until verified" do
      # CONSUMER BUILD
      # publish pact
      publish_response = put("/pacts/provider/Bar/consumer/Foo/version/1", pact_content_1, request_headers)

      # PROVIDER BUILD 1
      # get pacts for verification
      for_verification_response = get("/pacts/provider/Bar/for-verification", nil, request_headers)
      pending = JSON.parse(for_verification_response.body)["_embedded"]["pacts"][0]["verificationProperties"]["pending"]
      expect(pending).to be true

      # fetch pact
      pact_url = JSON.parse(last_response.body)["_embedded"]["pacts"][0]["_links"]["self"]["href"]
      pact_response = get pact_url, nil, request_headers

      # verify pact... failure...

      # publish failure verification results
      verification_results_url = JSON.parse(pact_response.body)["_links"]["pb:publish-verification-results"]["href"]
      post(verification_results_url, failed_verification_results, request_headers)

      # PROVIDER BUILD 2
      # get pacts for verification
      for_verification_response = get("/pacts/provider/Bar/for-verification", nil, request_headers)
      pending = JSON.parse(for_verification_response.body)["_embedded"]["pacts"][0]["verificationProperties"]["pending"]
      # still pending
      expect(pending).to be true

      # verify pact... success!

      # publish successful verification results
      post(verification_results_url, successful_verification_results, request_headers)

      # PROVIDER BUILD 3
      # get pacts for verification
      for_verification_response = get("/pacts/provider/Bar/for-verification", nil, request_headers)
      pending = JSON.parse(for_verification_response.body)["_embedded"]["pacts"][0]["verificationProperties"]["pending"]
      # not pending any more
      expect(pending).to be false
    end
  end
end