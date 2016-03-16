require 'spec_helper'
require 'pact_broker/api/resources/pact'
require 'rack/test'
require 'pact_broker/pacts/service'

module PactBroker::Api

  module Resources

    describe Pact do

      include Rack::Test::Methods

      let(:app) { PactBroker::API }
      let(:json) { {some: 'json'}.to_json }

      describe "PUT" do

        subject { put "/pacts/provider/Provider/consumer/Consumer/version/1.2", json, {'CONTENT_TYPE' => "application/json"} ; last_response }

        let(:response) { subject; last_response }

        context "with invalid JSON" do
          let(:json) { '{' }

          it "returns a 400 response" do
            expect(response.status).to eq 400
          end

          it "returns a JSON content type" do
            expect(response.headers['Content-Type']).to eq "application/json;charset=utf-8"
          end

          it "returns an error message" do
            expect(JSON.parse(response.body)["error"]).to match /Error parsing JSON/
          end
        end

        context "with validation errors" do

          let(:errors) { double(:errors, full_messages: ['messages']) }

          before do
            allow_any_instance_of(Contracts::PutPactParamsContract).to receive(:validate).and_return(false)
            allow_any_instance_of(Contracts::PutPactParamsContract).to receive(:errors).and_return(errors)
          end

          it "returns a 400 error" do
            expect(subject).to be_a_json_error_response 'messages'
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

          it "returns a 409 response" do
            expect(response.status).to eq 409
          end

          it "returns a text response" do
            expect(response.headers['Content-Type']).to eq 'text/plain'
          end

          it "returns the messages in the response body" do
            expect(response.body).to eq "message1\nmessage2"
          end
        end

      end

      describe "DELETE" do

        subject { delete "/pacts/provider/Provider/consumer/Consumer/version/1.2", json, {'CONTENT_TYPE' => "application/json"} ; last_response }

        let(:pact) { double('pact') }
        let(:pact_service) { PactBroker::Pacts::Service }
        let(:response) { subject; last_response }

        before do
          allow(pact_service).to receive(:find_pact).and_return(pact)
          allow(pact_service).to receive(:delete)
        end

        context "when the pact exists" do

          it "deletes the pact using the pact service" do
            expect(pact_service).to receive(:delete).with(instance_of(PactBroker::Pacts::PactParams))
            subject
          end

          it "returns a 204" do
            expect(subject.status).to eq 204
          end
        end

        context "when the pact does not exist" do
          let(:pact) { nil }

          it "returns a 404" do
            expect(subject.status).to eq 404
          end

        end
      end
    end
  end
end
