RSpec.describe "the pending lifecycle of a pact (with no tags)" do
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

  def publish_pact
    put("/pacts/provider/Bar/consumer/Foo/version/1", pact_content_1, request_headers)
  end

  def get_pacts_for_verification
    get("/pacts/provider/Bar/for-verification", nil, request_headers)
  end

  def pact_url_from(pacts_for_verification_response)
    JSON.parse(pacts_for_verification_response.body)["_embedded"]["pacts"][0]["_links"]["self"]["href"]
  end

  def get_pact(pact_url)
    get pact_url, nil, request_headers
  end

  def verification_results_url_from(pact_response)
    JSON.parse(pact_response.body)["_links"]["pb:publish-verification-results"]["href"]
  end

  def publish_verification_results(verification_results_url, results)
    post(verification_results_url, results, request_headers)
  end

  def pending_from(pacts_for_verification_response)
    JSON.parse(pacts_for_verification_response.body)["_embedded"]["pacts"][0]["verificationProperties"]["pending"]
  end


  context "a pact" do
    describe "when it is first published" do
      it "is pending" do
        publish_pact
        pacts_for_verification_response = get_pacts_for_verification
        pending = pending_from(pacts_for_verification_response)
        expect(pending).to be true
      end
    end

    describe "when it is verified unsuccessfully" do
      it "is still pending" do
        # CONSUMER BUILD
        # publish pact
        publish_pact

        # PROVIDER BUILD
        # fetch pacts to verify
        pacts_for_verification_response = get_pacts_for_verification
        pact_url = pact_url_from(pacts_for_verification_response)
        pact_response = get_pact(pact_url)

        # verify pact... failure...

        # publish failure verification results
        verification_results_url = verification_results_url_from(pact_response)
        publish_verification_results(verification_results_url, failed_verification_results)

        # ANOTHER PROVIDER BUILD
        # get pacts for verification
        pacts_for_verification_response = get_pacts_for_verification
        pending = pending_from(pacts_for_verification_response)
        # still pending
        expect(pending).to be true
      end
    end

    describe "when it is verified successfully" do
      it "is no longer pending" do
        # CONSUMER BUILD
        publish_pact

        # PROVIDER BUILD
        pacts_for_verification_response = get_pacts_for_verification

        # fetch pact
        pact_url = pact_url_from(pacts_for_verification_response)
        pact_response = get_pact(pact_url)

        # verify pact... success!

        # publish failure verification results
        verification_results_url = verification_results_url_from(pact_response)
        publish_verification_results(verification_results_url, successful_verification_results)

        # ANOTHER PROVIDER BUILD 2
        # get pacts for verification
        # publish successful verification results
        pacts_for_verification_response = get_pacts_for_verification
        pending = pending_from(pacts_for_verification_response)
        # not pending any more
        expect(pending).to be false
      end
    end
  end
end
