describe "Get provider pacts for verification" do
  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }
  let(:pacts) { last_response_body[:_embedded][:'pacts'] }
  let(:query) do
    {
      consumer_version_selectors: [ { tag: "prod", latest: "true" }]
    }
  end

  subject { get(path, query) }

  context "when the provider exists" do
    before do
      td.create_provider("Provider")
        .create_consumer("Consumer")
        .create_consumer_version("0.0.1")
        .create_pact(json_content: { some: "content" }.to_json)
        .create_consumer("Consumer 2")
        .create_consumer_version("4.5.6")
        .create_consumer_version_tag("prod")
        .create_pact(json_content: { some: "other content" }.to_json)
    end

    let(:path) { "/pacts/provider/Provider/for-verification" }

    context "when using GET" do
      it "returns a 200 HAL JSON response" do
        expect(subject).to be_a_hal_json_success_response
      end

      it "returns a list of links to the pacts" do
        expect(pacts.size).to eq 1
      end

      it "returns a deprecation notice" do
        expect(last_response_body[:_embedded][:pacts].first[:verificationProperties][:notices].first[:text]).to start_with("WARNING")
      end

      context "when the provider does not exist" do
        let(:path) { "/pacts/provider/ProviderThatDoesNotExist/for-verification" }

        it "returns a 404 response" do
          expect(subject).to be_a_404_response
        end
      end
    end

    context "when using POST" do
      let(:request_body) do
        {
          consumerVersionSelectors: [ { tag: "prod", latest: true }],
          includePendingStatus: false,
          providerVersionTags: ["main"]
        }
      end

      let(:request_headers) do
        {
          "CONTENT_TYPE" => "application/json",
          "HTTP_ACCEPT" => "application/hal+json"
        }
      end

      let(:fixture) do
        {
          request: { path: path, headers: rack_env_to_http_headers(request_headers), body: request_body },
          response: { status: subject.status, headers: determinate_headers(subject.headers), body: JSON.parse(subject.body)}
        }
      end

      subject { post(path, request_body.to_json, request_headers) }

      # The metadata is different when the database IDs are different
      it "matches the expected body", skip: !PactBroker::TestDatabase.sqlite? do
        Approvals.verify(fixture, :name => "get_provider_pacts_for_verification", format: :json)
      end

      it "returns a list of links to the pacts" do
        expect(pacts.size).to eq 1
      end

      it "does not include a deprecation notice" do
        expect(last_response_body[:_embedded][:pacts].first[:verificationProperties][:notices].first[:text]).to_not start_with("WARNING")
      end

      context "when the provider does not exist" do
        let(:path) { "/pacts/provider/ProviderThatDoesNotExist/for-verification" }

        it "returns a 404 response" do
          expect(subject).to be_a_404_response
        end
      end
    end
  end
end
