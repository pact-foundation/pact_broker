describe "Creating a webhook" do
  before do
    td.create_pact_with_hierarchy("Some Consumer", "1", "Some Provider")
  end

  let(:headers) { {"CONTENT_TYPE" => "application/json"} }
  let(:response_body) { JSON.parse(subject.body, symbolize_names: true)}
  let(:webhook_json) { webhook_hash.to_json }
  let(:provider) { nil }
  let(:consumer) { nil }
  let(:webhook_hash) do
    {
      description: "trigger build",
      enabled: false,
      provider: provider,
      consumer: consumer,
      events: [{
        name: "contract_content_changed"
      }],
      request: {
        method: "POST",
        url: "https://example.org",
        headers: {
          :"Content-Type" => "application/json"
        },
        body: {
          a: "body"
        }
      }
    }.compact
  end

  subject { post(path, webhook_json, headers) }

  context "for a consumer and provider" do
    let(:path) { "/webhooks/provider/Some%20Provider/consumer/Some%20Consumer" }

    context "with invalid attributes" do
      let(:webhook_hash) { {} }

      its(:status) { is_expected.to be 400 }

      it "returns a JSON content type" do
        expect(subject.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
      end

      it "returns the validation errors" do
        expect(response_body[:errors]).to_not be_empty
      end
    end

    context "with valid attributes" do
      its(:status) { is_expected.to be 201 }

      it "returns the Location header" do
        expect(subject.headers["Location"]).to match(%r{http://example.org/webhooks/.+})
      end

      it "returns a JSON Content Type" do
        expect(subject.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
      end

      it "returns the newly created webhook" do
        expect(response_body).to include webhook_hash
      end
    end
  end

  context "for a provider" do
    let(:path) { "/webhooks" }
    let(:provider) { { name: "Some Provider" } }

    its(:status) { is_expected.to eq 201 }

    it "creates a webhook without a consumer" do
      subject
      expect(PactBroker::Webhooks::Webhook.first.provider).to_not be nil
      expect(PactBroker::Webhooks::Webhook.first.consumer).to be nil
    end

    context "with pattern" do
      let(:provider) { { pattern: "* Provider" } }

      its(:status) { is_expected.to eq 201 }

      it "creates a webhook without explicit consumer and provider with provider pattern" do
        subject
        expect(PactBroker::Webhooks::Webhook.first.provider).to be nil
        expect(PactBroker::Webhooks::Webhook.first.consumer).to be nil
        expect(PactBroker::Webhooks::Webhook.first.provider_pattern).to eq "* Provider"
      end
    end
  end

  context "for a consumer" do
    let(:path) { "/webhooks" }
    let(:consumer) { { name: "Some Consumer" } }

    its(:status) { is_expected.to eq 201 }

    it "creates a webhook without a provider" do
      subject
      expect(PactBroker::Webhooks::Webhook.first.consumer).to_not be nil
      expect(PactBroker::Webhooks::Webhook.first.provider).to be nil
    end

    context "with pattern" do
      let(:consumer) { { pattern: "* Consumer" } }

      its(:status) { is_expected.to eq 201 }

      it "creates a webhook without explicit consumer and provider with consumer pattern" do
        subject
        expect(PactBroker::Webhooks::Webhook.first.provider).to be nil
        expect(PactBroker::Webhooks::Webhook.first.consumer).to be nil
        expect(PactBroker::Webhooks::Webhook.first.consumer_pattern).to eq "* Consumer"
      end
    end

    context 'with both pattern and name' do
      let(:consumer) { { name: "Some Consumer", pattern: "* Consumer" } }

      its(:status) { is_expected.to eq 400 }

      it "returns the validation errors" do
        expect(response_body[:errors]).to_not be_empty
      end
    end
  end

  context "with no consumer or provider" do
    let(:path) { "/webhooks" }

    its(:status) { is_expected.to be 201 }

    it "creates a webhook without a provider" do
      subject
      expect(PactBroker::Webhooks::Webhook.first.consumer).to be nil
      expect(PactBroker::Webhooks::Webhook.first.provider).to be nil
    end
  end

  context "with a UUID" do
    let(:path) { "/webhooks/1234123412341234" }

    before do
      webhook_hash[:provider] = { name: "Some Provider" }
      webhook_hash[:consumer] = { name: "Some Consumer" }
    end

    subject { put(path, webhook_json, headers) }

    its(:status) { is_expected.to be 201 }

    it "is expected to have a consumer and provider" do
      subject
      expect(PactBroker::Webhooks::Webhook.first.consumer).to_not be nil
      expect(PactBroker::Webhooks::Webhook.first.provider).to_not be nil
    end
  end

  context "with the old path" do
    let(:path) { "/pacts/provider/Some%20Provider/consumer/Some%20Consumer/webhooks" }

    its(:status) { is_expected.to be 201 }

    it "returns the Location header" do
      expect(subject.headers["Location"]).to match(%r{http://example.org/webhooks/.+})
    end

    it "returns a JSON Content Type" do
      expect(subject.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
    end

    it "returns the newly created webhook" do
      expect(response_body).to include webhook_hash
    end
  end
end
