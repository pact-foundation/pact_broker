require 'pact_broker/api/resources/base_resource'

module PactBroker
  module Api
    module Resources
      describe BaseResource do
        let(:request) { double('request', uri: uri, base_uri: URI("http://example.org/")).as_null_object }
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

        describe "base_url" do
          context "when PactBroker.configuration.base_url is not nil" do
            before do
              allow(PactBroker.configuration).to receive(:base_url).and_return("http://foo")
            end

            it "returns the configured base URL" do
              expect(subject.base_url).to eq "http://foo"
            end
          end

          context "when PactBroker.configuration.base_url is nil" do
            before do
              allow(PactBroker.configuration).to receive(:base_url).and_return(nil)
            end

            it "returns the base URL from the request" do
              expect(subject.base_url).to eq "http://example.org"
            end
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

          it "calls super in its constructor" do
            expect(PactBroker.configuration.before_resource).to receive(:call)
            resource.new(request, response)
          end

          it "calls super in finish_request" do
            expect(PactBroker.configuration.after_resource).to receive(:call)
            resource.new(request, response).finish_request
          end
        end
      end
    end
  end
end
