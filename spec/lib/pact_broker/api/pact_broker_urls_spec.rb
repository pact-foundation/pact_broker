require 'pact_broker/api/pact_broker_urls'

module PactBroker
  module Api
    describe PactBrokerUrls do

      let(:base_url) { "http://example.org" }

      describe "templated_tag_url_for_pacticipant" do
        subject { PactBrokerUrls.templated_tag_url_for_pacticipant("Bar", base_url) }

        it { is_expected.to eq "http://example.org/pacticipants/Bar/versions/{version}/tags/{tag}" }
      end
    end
  end
end
