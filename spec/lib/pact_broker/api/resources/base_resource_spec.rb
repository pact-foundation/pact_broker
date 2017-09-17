require 'pact_broker/api/resources/base_resource'

module PactBroker
  module Api
    module Resources
      describe BaseResource do
        let(:request) { double('request', uri: uri) }
        let(:response) { double('response') }
        let(:uri) { URI('http://example.org/path?query') }

        subject { BaseResource.new(request, response) }

        its(:resource_url) { is_expected.to eq 'http://example.org/path' }
      end
    end
  end
end
