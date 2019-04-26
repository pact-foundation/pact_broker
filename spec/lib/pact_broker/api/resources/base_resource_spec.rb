require 'pact_broker/api/resources/base_resource'

module PactBroker
  module Api
    module Resources
      describe BaseResource do
        let(:request) { double('request', uri: uri).as_null_object }
        let(:response) { double('response') }
        let(:uri) { URI('http://example.org/path?query') }

        subject { BaseResource.new(request, response) }

        its(:resource_url) { is_expected.to eq 'http://example.org/path' }

        describe "options" do
          subject { options "/"; last_response }

          it "returns a list of allowed methods" do
            expect(subject.headers['Access-Control-Allow-Methods']).to eq "GET, OPTIONS"
          end
        end
      end

      ALL_RESOURCES = ObjectSpace.each_object(::Class).select {|klass| klass < BaseResource }

      ALL_RESOURCES.each do | resource |
        describe resource do
          let(:request) { double('request', uri: URI("http://example.org")).as_null_object }
          let(:response) { double('response') }

          it "includes OPTIONS in the list of allowed_methods" do
            expect(resource.new(request, response).allowed_methods).to include "OPTIONS"
          end
        end
      end
    end
  end
end
