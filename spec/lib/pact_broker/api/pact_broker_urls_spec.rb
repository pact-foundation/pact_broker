require 'pact_broker/api/pact_broker_urls'

module PactBroker
  module Api
    describe PactBrokerUrls do

      let(:base_url) { "http://example.org" }
      let(:pact) { double('pact', consumer: consumer, provider: provider, consumer_version_number: "123") }
      let(:consumer) { double('pacticipant', name: "Foo") }
      let(:provider) { double('pacticipant', name: "Bar") }

      describe "templated_tag_url_for_pacticipant" do
        subject { PactBrokerUrls.templated_tag_url_for_pacticipant("Bar", base_url) }

        it { is_expected.to eq "http://example.org/pacticipants/Bar/versions/{version}/tags/{tag}" }
      end

      describe "pact_triggered_webhooks_url" do
        subject { PactBrokerUrls.pact_triggered_webhooks_url(pact, base_url) }

        it { is_expected.to eq "http://example.org/pacts/provider/Bar/consumer/Foo/version/123/triggered-webhooks" }
      end
    end
  end
end
