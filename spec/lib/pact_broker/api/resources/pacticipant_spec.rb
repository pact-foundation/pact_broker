require "spec_helper"
require "pact_broker/api/resources/pacticipant"

module PactBroker::Api
  module Resources
    describe Pacticipant do
      describe "PUT" do
        before do
          allow(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).and_return(pacticpant)
        end

        let(:pacticpant) { double('pacticipant') }
        let(:path) { "/pacticipants/foo" }
        let(:headers) { {"CONTENT_TYPE" => "application/json"} }
        let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}

        subject { put(path, "", headers) }

        context "with an empty body" do
          its(:status) { is_expected.to eq 200 }
        end
      end

      describe "PATCH" do
        before do
          allow(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).and_return(pacticpant)
        end

        let(:pacticpant) { nil }
        let(:path) { "/pacticipants/foo" }
        let(:headers) { {"CONTENT_TYPE" => "application/merge-patch+json"} }
        let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}

        subject { patch(path, "", headers) }

        context "with an empty body" do
          its(:status) { is_expected.to eq 201 }
        end
      end

      describe "DELETE" do
        before do
          allow(PactBroker::Pacticipants::Service).to receive(:delete)
          allow(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).and_return(pacticpant)
        end

        let(:pacticpant) { double("pacticpant") }

        subject { delete("/pacticipants/Some%20Service" ) }

        context "when the resource exists" do
          it "deletes the pacticpant by name" do
            expect(PactBroker::Pacticipants::Service).to receive(:delete).with("Some Service")
            subject
          end

          it "returns a 204 OK" do
            subject
            expect(last_response.status).to eq 204
          end
        end

        context "when the resource doesn't exist" do

          let(:pacticpant) { nil }

          it "returns a 404 Not Found" do
            subject
            expect(last_response.status).to eq 404
          end
        end

        context "when an error occurs" do
          before do
            allow(PactBroker::Pacticipants::Service).to receive(:delete).and_raise("An error")
          end

          let(:response_body) { JSON.parse(last_response.body, symbolize_names: true) }

          it "returns a 500 Internal Server Error" do
            subject
            expect(last_response.status).to eq 500
          end

          it "returns an error message" do
            subject
            expect(response_body[:error][:message]).to eq "An error"
          end
        end
      end
    end
  end
end
