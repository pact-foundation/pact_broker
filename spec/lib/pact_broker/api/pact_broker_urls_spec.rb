require 'pact_broker/api/pact_broker_urls'

module PactBroker
  module Api
    describe PactBrokerUrls do

      # Regex find all the URL parameter names
      # \/\{[^\}\s\[\(\.]+\}

      let(:base_url) { "http://example.org" }
      let(:consumer_name) { "Foo/Foo" }
      let(:provider_name) { "Bar/Bar" }
      let(:pact) { double('pact', consumer: consumer, provider: provider, consumer_version_number: "123/456", pact_version_sha: "5hbfu") }
      let(:consumer) { double('pacticipant', name: consumer_name) }
      let(:provider) { double('pacticipant', name: provider_name) }
      let(:verification) do
        instance_double(PactBroker::Domain::Verification,
          consumer_name: consumer_name,
          provider_name: provider_name,
          pact_version_sha: "1234",
          number: "1")
      end

      describe "pact_url" do
        subject { PactBrokerUrls.pact_url(base_url, pact) }

        it { is_expected.to eq "http://example.org/pacts/provider/Bar%2FBar/consumer/Foo%2FFoo/version/123%2F456" }
      end

      describe "templated_tag_url_for_pacticipant" do
        subject { PactBrokerUrls.templated_tag_url_for_pacticipant(provider_name, base_url) }

        it { is_expected.to eq "http://example.org/pacticipants/Bar%2FBar/versions/{version}/tags/{tag}" }
      end

      describe "pact_triggered_webhooks_url" do
        subject { PactBrokerUrls.pact_triggered_webhooks_url(pact, base_url) }

        it { is_expected.to eq "http://example.org/pacts/provider/Bar%2FBar/consumer/Foo%2FFoo/version/123%2F456/triggered-webhooks" }
      end

      describe "verification_triggered_webhooks_url" do
        subject { PactBrokerUrls.verification_triggered_webhooks_url(verification, base_url) }

        it { is_expected.to eq "http://example.org/pacts/provider/Bar%2FBar/consumer/Foo%2FFoo/pact-version/1234/verification-results/1/triggered-webhooks" }
      end

      describe "templated_diff_url" do
        subject { PactBrokerUrls.templated_diff_url(pact, base_url) }

        it { is_expected.to eq "http://example.org/pacts/provider/Bar%2FBar/consumer/Foo%2FFoo/pact-version/5hbfu/diff/pact-version/{pactVersion}" }
      end
    end
  end
end
