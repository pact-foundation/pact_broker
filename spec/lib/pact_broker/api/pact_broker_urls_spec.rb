require 'pact_broker/api/pact_broker_urls'

module PactBroker
  module Api
    describe PactBrokerUrls do

      let(:base_url) { "http://example.org" }
      let(:version) { instance_double("PactBroker::Domain::Version", number: "1", pacticipant: pacticipant) }
      let(:pacticipant) { instance_double("PactBroker::Domain::Pacticipant", name: "Foo") }

      describe "templated_tag_url_for_pacticipant" do
        subject { PactBrokerUrls.templated_tag_url_for_pacticipant("Foo", base_url) }

        it { is_expected.to eq "http://example.org/pacticipants/Foo/versions/{version}/tags/{tag}" }
      end

      describe "templated_environment_url" do
        subject { PactBrokerUrls.templated_environment_url(version, base_url) }

        it { is_expected.to eq "http://example.org/pacticipants/Foo/versions/1/environments/{environment}" }
      end
    end
  end
end
