require 'spec_helper'
require 'pact_broker/api/resources/pacticipants'

module PactBroker
  module Api
    module Resources

      describe Pacticipants do

        describe "POST" do
          let(:params) { {name: 'New Consumer'} }
          let(:json) { params.to_json }
          let(:model) { instance_double(model_class, validate: errors) }
          let(:created_model) { instance_double(model_class) }
          let(:errors) { [] }
          let(:model_class) { PactBroker::Domain::Pacticipant }
          let(:decorator_class) { PactBroker::Api::Decorators::PacticipantDecorator }
          let(:decorator) { instance_double(decorator_class, to_json: response_json, from_json: model) }
          let(:response_json) { {some: 'json'}.to_json }

          before do
            allow(model_class).to receive(:new).and_return(model)
            allow(PactBroker::Services::PacticipantService).to receive(:create).and_return(created_model)
            allow(decorator_class).to receive(:new).with(model).and_return(decorator)
            allow(decorator_class).to receive(:new).with(created_model).and_return(decorator)
          end

          subject { post "/pacticipants", json, 'CONTENT_TYPE' => 'application/json' }

          context "structurally incorrect JSON" do
            let(:json) { "{" }

            it "returns a 400" do
              subject
              expect(last_response.status).to eq 400
            end
          end

          context "when the model is invalid" do
            let(:errors) { ['error'] }

            it "returns a 400" do
              subject
              expect(last_response.status).to eq 400
            end
          end

          context "with valid JSON" do
            it "creates the pacticipant" do
              expect(PactBroker::Services::PacticipantService).to receive(:create).with(params)
              subject
            end

            it "parses the request JSON" do
              expect(decorator).to receive(:from_json).with(json)
              subject
            end

            it "returns a 201" do
              subject
              expect(last_response.status).to eq 201
            end

            it "returns a Content-Type of application/hal+json" do
              subject
              expect(last_response.headers['Content-Type']).to eq 'application/hal+json'
            end

            it "creates a JSON representation of the new pacticipant" do
              expect(decorator_class).to receive(:new).with(created_model)
              expect(decorator).to receive(:to_json).with(instance_of(Decorators::DecoratorContext))
              subject
            end

            it "includes the JSON pacticipant in the response body" do
              subject
              expect(last_response.body).to eq response_json
            end

            it "includes the newly created Location" do
              subject
              expect(last_response.headers['Location']).to eq "http://example.org/pacticpants/New%20Consumer"
            end
          end
        end

      end
    end

  end
end