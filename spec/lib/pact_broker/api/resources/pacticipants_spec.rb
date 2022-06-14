require "spec_helper"
require "pact_broker/api/resources/pacticipants"

module PactBroker
  module Api
    module Resources
      describe Pacticipants do
        describe "POST" do
          let(:params) { { name: "New Consumer" } }
          let(:request_body) { params.to_json }
          let(:created_model) { instance_double(model_class) }
          let(:errors) { {} }
          let(:model_class) { PactBroker::Domain::Pacticipant }
          let(:decorator_class) { PactBroker::Api::Decorators::PacticipantDecorator }
          let(:parsed_model) { OpenStruct.new(name: "New Consumer") }
          let(:decorator) { instance_double(decorator_class, to_json: response_json, from_json: parsed_model) }
          let(:response_json) { {some: "json"}.to_json }
          let(:schema) { PactBroker::Api::Contracts::PacticipantSchema }

          before do
            allow(PactBroker::Pacticipants::Service).to receive(:create).and_return(created_model)
            allow(decorator_class).to receive(:new).and_return(decorator)
            allow(schema).to receive(:call).and_return(errors)
          end

          subject { post "/pacticipants", request_body, "CONTENT_TYPE" => "application/json" }

          context "structurally incorrect JSON" do
            let(:request_body) { "{" }

            it "returns a 400" do
              subject
              expect(last_response.status).to eq 400
            end
          end

          context "with an empty body" do
            let(:request_body) { "" }

            it "returns a 400" do
              subject
              expect(last_response.status).to eq 400
            end
          end

          context "when the model is invalid" do
            let(:errors) { { "some" => ["errors"] } }

            it "returns a 400" do
              subject
              expect(last_response.status).to eq 400
            end
          end

          context "with valid JSON" do
            it "creates the pacticipant" do
              expect(PactBroker::Pacticipants::Service).to receive(:create).with(:name => "New Consumer")
              subject
            end

            it "parses the request JSON" do
              expect(decorator).to receive(:from_json).with(request_body)
              subject
            end

            it "returns a 201" do
              subject
              expect(last_response.status).to eq 201
            end

            it "returns a Content-Type of application/hal+json" do
              subject
              expect(last_response.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
            end

            it "creates a JSON representation of the new pacticipant" do
              expect(decorator_class).to receive(:new).with(created_model)
              expect(decorator).to receive(:to_json).with(user_options: instance_of(Decorators::DecoratorContext))
              subject
            end

            it "includes the JSON pacticipant in the response body" do
              subject
              expect(last_response.body).to eq response_json
            end

            it "includes the newly created Location" do
              subject
              expect(last_response.headers["Location"]).to eq "http://example.org/pacticpants/New%20Consumer"
            end
          end
        end
      end
    end
  end
end
