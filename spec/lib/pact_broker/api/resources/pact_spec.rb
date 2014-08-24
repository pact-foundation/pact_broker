require 'spec_helper'
require 'pact_broker/api/resources/pact'
require 'rack/test'

module PactBroker::Api

  module Resources

    describe Pact do

      include Rack::Test::Methods

      let(:app) { PactBroker::API }
      let(:json) { {some: 'json'}.to_json }

      describe "PUT" do

        subject { put "/pacts/provider/Provider/consumer/Consumer/version/1.2", json, {'CONTENT_TYPE' => "application/json"} }

        let(:response) { subject; last_response }

        context "with invalid JSON" do
          let(:json) { '{' }

          it "returns a 400 response" do
            expect(response.status).to eq 400
          end

          it "returns a JSON content type" do
            expect(response.headers['Content-Type']).to eq "application/json"
          end

          it "returns an error message" do
            expect(JSON.parse(response.body)["error"]).to match /Error parsing JSON/
          end
        end

        context "with a potential duplicate pacticipant" do

          let(:pacticipant_service) { PactBroker::Services::PacticipantService }
          let(:messages) { ["message1", "message2"] }

          before do
            allow(pacticipant_service).to receive(:messages_for_potential_duplicate_pacticipants).and_return(messages)
          end

          it "checks for duplicates" do
            expect(pacticipant_service).to receive(:messages_for_potential_duplicate_pacticipants).with(['Consumer', 'Provider'], 'http://example.org')
            response
          end

          it "returns a 400 response" do
            expect(response.status).to eq 400
          end

          it "returns a text response" do
            expect(response.headers['Content-Type']).to eq 'text/plain'
          end

          it "returns the messages in the response body" do
            expect(response.body).to eq "message1\nmessage2"
          end
        end

      end

    end
  end

end
