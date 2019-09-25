require 'spec/support/test_data_builder'

describe "Get latest verification for pact" do
  before do
    td
      .create_consumer("Consumer")
      .create_consumer_version("1.2.3")
      .create_provider("Another provider")
      .create_pact
      .create_verification(number: 1, provider_version: "5")
      .create_provider("Provider")
      .create_pact
      .create_verification(number: 1, provider_version: "3")
      .create_verification(number: 2, provider_version: "4")
  end

  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }
  let(:content_type) { "application/vnd.pactbrokerextended.v1+json" }

  subject { get(path, nil, "HTTP_ACCEPT" => content_type) }

  context "by pact version" do
    let!(:path) { "/pacts/provider/Provider/consumer/Consumer/pact-version/#{td.pact.pact_version_sha}/verification-results/latest" }

    it "returns a 200 OK" do
      expect(subject.status).to eq 200
      expect(subject.headers['Content-Type']).to include content_type
    end

    it "returns the verification" do
      expect(last_response_body[:providerApplicationVersion]).to eq "4"
    end
  end

  context "by consumer version" do
    let(:path) { "/pacts/provider/Provider/consumer/Consumer/version/1.2.3/verification-results/latest" }

    it "returns the verification" do
      expect(last_response_body[:providerApplicationVersion]).to eq "4"
    end
  end
end
