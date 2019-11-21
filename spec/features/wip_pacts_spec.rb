RSpec.describe "the lifecycle of a WIP pact" do
  let(:pact_content_1) { { interactions: [{ some: 'interaction'}] }.to_json }
  let(:pact_content_2) { { interactions: [{ some: 'other interaction'}] }.to_json }
  let(:request_headers) { { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/hal+json"} }
  let(:provider_version_number) { "2" }
  let(:failed_verification_results) do
    {
      providerApplicationVersion: provider_version_number,
      success: false
    }.to_json
  end
  let(:successful_verification_results) do
    {
      providerApplicationVersion: provider_version_number,
      success: true
    }.to_json
  end
  let(:pacts_for_verification_request_body) do
    {
      consumerVersionSelectors: [ { tag: "master", latest: true } ],
      providerVersionTags: ["master"],
      includeWipPactsSince: start_date
    }.to_json
  end
  let(:start_date) { (Date.today - 1).to_datetime }

  def publish_pact_with_master_tag
    put("/pacts/provider/Bar/consumer/Foo/version/1", pact_content_1, request_headers)
    put("/pacticipants/Foo/versions/1/tags/master", nil, request_headers)
  end

  def publish_pact_with_feature_tag
    put("/pacts/provider/Bar/consumer/Foo/version/2", pact_content_2, request_headers)
    put("/pacticipants/Foo/versions/2/tags/feat-x", nil, request_headers)
  end

  def get_pacts_for_verification
    post("/pacts/provider/Bar/for-verification", pacts_for_verification_request_body, request_headers)
  end

  def wip_pact_url_from(pacts_for_verification_response)
    wip_pacts_from(pacts_for_verification_response).first["_links"]["self"]["href"]
  end

  def get_pact(pact_url)
    get pact_url, nil, request_headers
  end

  def verification_results_url_from(pact_response)
    JSON.parse(pact_response.body)["_links"]["pb:publish-verification-results"]["href"]
  end

  def publish_verification_results_with_tag_master(verification_results_url, results)
    post(verification_results_url, results, request_headers)
    put("/pacticipants/Bar/versions/#{provider_version_number}/tags/master", nil, request_headers)
  end

  def pending_status_from(pacts_for_verification_response)
    JSON.parse(pacts_for_verification_response.body)["_embedded"]["pacts"][0]["verificationProperties"]["pending"]
  end

  def wip_pacts_from(pacts_for_verification_response)
    JSON.parse(pacts_for_verification_response.body)["_embedded"]["pacts"].select do | pact |
      pact["verificationProperties"]["wip"]
    end
  end

  context "when the includeWipPactsSince date is specified" do
    context "a pact published afer the specified date, with a tag that is not specified explictly in the 'pacts for verification' request" do
      describe "when it is first published" do
        it "is included in the list of pacts to verify as a WIP pact" do
          publish_pact_with_master_tag
          publish_pact_with_feature_tag

          pacts_for_verification_response = get_pacts_for_verification
          expect(wip_pacts_from(pacts_for_verification_response).size).to eq 1
        end
      end

      describe "when it is verified unsuccessfully" do
        it "is still included as a WIP pact" do
          # CONSUMER BUILD
          # publish pact
          publish_pact_with_master_tag
          publish_pact_with_feature_tag

          # PROVIDER BUILD
          # fetch pacts to verify
          pacts_for_verification_response = get_pacts_for_verification
          pact_url = wip_pact_url_from(pacts_for_verification_response)
          pact_response = get_pact(pact_url)

          # verify pact... failure...

          # publish failure verification results
          verification_results_url = verification_results_url_from(pact_response)
          publish_verification_results_with_tag_master(verification_results_url, failed_verification_results)

          # ANOTHER PROVIDER BUILD
          # get pacts for verification
          pacts_for_verification_response = get_pacts_for_verification
          # still pending
          expect(wip_pacts_from(pacts_for_verification_response).size).to eq 1
        end
      end

      describe "when it is verified successfully" do
        it "is no longer included in the list of pacts to verify" do
          # CONSUMER BUILD
          publish_pact_with_master_tag
          publish_pact_with_feature_tag

          # PROVIDER BUILD
          # fetch pacts to verify
          pacts_for_verification_response = get_pacts_for_verification
          pact_url = wip_pact_url_from(pacts_for_verification_response)
          pact_response = get_pact(pact_url)

          # verify pact... success!

          # publish failure verification results
          verification_results_url = verification_results_url_from(pact_response)
          publish_verification_results_with_tag_master(verification_results_url, successful_verification_results)


          # ANOTHER PROVIDER BUILD 2
          # get pacts for verification
          # publish successful verification results
          pacts_for_verification_response = get_pacts_for_verification
          # not wip any more
          expect(wip_pacts_from(pacts_for_verification_response).size).to eq 0
        end
      end

  end

  end
end
