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
      TestDataBuilder.new
        .create_provider("Provider")
        .create_consumer("Consumer")
        .create_consumer_version("0.0.1", branch: "main")
        .create_pact
        .create_consumer("Consumer 2")
        .create_consumer_version("4.5.6")
        .create_consumer_version_tag("prod")
        .create_pact
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
          consumerVersionSelectors: [ { tag: "prod", latest: true }]
        }
      end

      let(:request_headers) do
        {
          'CONTENT_TYPE' => 'application/json',
          'HTTP_ACCEPT' => 'application/hal+json'
        }
      end

      subject { post(path, request_body.to_json, request_headers) }

      it "returns a list of links to the pacts" do
        expect(pacts.size).to eq 1
      end

      it "does not include a deprecation notice" do
        expect(last_response_body[:_embedded][:pacts].first[:verificationProperties][:notices].first[:text]).to_not start_with("WARNING")
      end

      context "when specifying a branch in the selector" do
        let(:request_body) do
          {
            consumerVersionSelectors: [ { branch: "main", latest: true }]
          }
        end

        it "returns a list of links to the pacts", pending: true do
          expect(pacts.size).to eq 1
        end
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
