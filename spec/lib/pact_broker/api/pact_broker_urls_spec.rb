require 'pact_broker/api/pact_broker_urls'

module PactBroker
  module Api
    describe PactBrokerUrls do

      let(:base_url) { "http://example.org" }
      let(:pact) { double('pact', consumer: consumer, provider: provider, consumer_version_number: "123") }
      let(:consumer) { double('pacticipant', name: "Foo") }
      let(:provider) { double('pacticipant', name: "Bar") }
      let(:verification) do
        instance_double(PactBroker::Domain::Verification,
          consumer_name: "Foo",
          provider_name: "Bar",
          pact_version_sha: "1234",
          number: "1")
      end

      describe "templated_tag_url_for_pacticipant" do
        subject { PactBrokerUrls.templated_tag_url_for_pacticipant("Bar", base_url) }

        it { is_expected.to eq "http://example.org/pacticipants/Bar/versions/{version}/tags/{tag}" }
      end

      describe "pact_triggered_webhooks_url" do
        subject { PactBrokerUrls.pact_triggered_webhooks_url(pact, base_url) }

        it { is_expected.to eq "http://example.org/pacts/provider/Bar/consumer/Foo/version/123/triggered-webhooks" }
      end

      describe "verification_triggered_webhooks_url" do
        subject { PactBrokerUrls.verification_triggered_webhooks_url(verification, base_url) }

        it { is_expected.to eq "http://example.org/pacts/provider/Bar/consumer/Foo/pact-version/1234/verification-results/1/triggered-webhooks" }
      end
    end
  end
end
