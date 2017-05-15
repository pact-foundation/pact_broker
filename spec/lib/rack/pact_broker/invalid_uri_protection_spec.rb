require 'rack/pact_broker/invalid_uri_protection'

module Rack
  module PactBroker
    describe InvalidUriProtection do

      let(:app) { InvalidUriProtection.new(->(env){ [200,{},[]] }) }

      subject { get "/badpath"; last_response }

      context "with a URI that the Ruby default URI library cannot parse" do

        before do
          # Can't use or stub URI.parse because rack test uses it to execute the actual test
          allow_any_instance_of(InvalidUriProtection).to receive(:parse).and_raise(URI::InvalidURIError)
        end

        it "returns a 404" do
          expect(subject.status).to eq 404
        end
      end

      context "when the URI can be parsed" do
        it "passes the request to the underlying app" do
          expect(subject.status).to eq 200
        end
      end
    end
  end
end
