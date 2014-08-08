require 'spec_helper'
require 'pact_broker/api/resources/pact'
require 'rack/test'

module PactBroker::Api

  module Resources

    describe Pact do

      include Rack::Test::Methods

      let(:app) { PactBroker::API }

      describe "PUT" do

        context "with invalid JSON" do

          before do
            put "/pacts/provider/Provider/consumer/Consumer/version/1.2", '{', {'CONTENT_TYPE' => "application/json"}
          end

          it "returns a 400 response" do
            expect(last_response.status).to eq 400
          end

          it "returns a JSON content type" do
            expect(last_response.headers['Content-Type']).to eq "application/json"
          end

          it "returns an error message" do
            expect(JSON.parse(last_response.body)).to eq "error" => "Invalid JSON"
          end
        end

      end

    end
  end

end
