require 'spec_helper'
require 'pact_broker/api/resources/environment'
require 'pact_broker/environments/service'
require 'pact_broker/matrix/service'

module PactBroker
  module Api
    module Resources
      describe Environment do
        let(:environment) { instance_double("PactBroker::Environments::Environment") }
        let(:environment_decorator) { instance_double("PactBroker::Api::Decorators::EnvironmentDecorator", :to_json => environment_json) }
        let(:environment_json) { {"some" => "environment"}.to_json }
        let(:environment_attributes) {
          {
            :pacticipant_name => "Condor",
            :pacticipant_version_number => "1.3.0",
            :environment_name => "prod"
          }
        }
        let(:contract) do
          instance_double('PactBroker::Contracts::EnvironmentContract', validate: valid, errors: errors)
        end

        let(:valid) { true }
        let(:errors) { instance_double('errors', messages: {some: 'errors'}) }

        before do
          allow(PactBroker::Matrix::Service).to receive(:refresh_environments) { |thing, &block| block.call if block }
          allow(Contracts::EnvironmentContract).to receive(:new).and_return(contract)
        end

        describe "DELETE" do
          before do
            allow(Environments::Service).to receive(:find).and_return(environment)
            allow(Environments::Service).to receive(:delete)
          end

          subject { delete("/pacticipants/Condor/versions/1.3.0/environments/prod" ) }

          context "when the environment exists" do
            it "deletes the environment by name" do
              expect(Environments::Service).to receive(:delete) .with(hash_including(environment_attributes))
              subject
            end

            it "returns a 204 OK" do
              subject
              expect(last_response.status).to eq 204
            end
          end

          context "when the environment doesn't exist" do
            let(:environment) { nil }

            it "returns a 404 Not Found" do
              subject
              expect(last_response.status).to eq 404
            end
          end

          context "when an error occurs" do
            before do
              allow(Environments::Service).to receive(:delete).and_raise("An error")
            end

            let(:response_body) { JSON.parse(last_response.body, symbolize_names: true) }

            it "returns a 500 Internal Server Error" do
              subject
              expect(last_response.status).to eq 500
            end

            it "returns an error message" do
              subject
              expect(response_body[:message]).to eq "An error"
            end

            it "returns the backtrace" do
              subject
              expect(response_body[:backtrace]).to be_instance_of(Array)
            end
          end
        end

        describe "GET" do
          before do
            allow(Environments::Service).to receive(:find).and_return(environment)
            allow(PactBroker::Api::Decorators::EnvironmentDecorator).to receive(:new).and_return(environment_decorator)
          end

          subject { get("/pacticipants/Condor/versions/1.3.0/environments/prod" ) }

          context "when the environment exists" do
            it "renders the environment" do
              subject
              expect(last_response.body).to eq environment_json
            end

            it "returns a success response" do
              subject
              expect(last_response).to be_successful
            end

          end

          context "when the environment does not exist" do
            let(:environment) { nil }

            it "returns a 404" do
              subject
              expect(last_response.status).to eq 404
            end
          end
        end

        describe "PUT" do
          let(:environment_url) { 'http://example.org/environment/url'}

          before do
            allow_any_instance_of(PactBroker::Api::Resources::Environment).to receive(:environment_url).and_return(environment_url)
            allow(Environments::Service).to receive(:find).and_return(environment)
            allow(PactBroker::Api::Decorators::EnvironmentDecorator).to receive(:new).and_return(environment_decorator)
          end

          subject { put("/pacticipants/Condor/versions/1.3.0/environments/prod", nil, "CONTENT_LENGTH" => "0", "CONTENT_TYPE" => "application/json") }

          it "valides the params" do
            expect(contract).to receive(:validate).with(hash_including(environment_name: "prod", pacticipant_name: "Condor", pacticipant_version_number: "1.3.0"))
            subject
          end

          it "returns a success response" do
            subject
            expect(last_response).to be_successful
          end

          context "when the params are invalid" do
            let(:valid) { false }

            it "returns a 400" do
              subject
              expect(last_response.status).to be 400
            end

            it "returns error messages" do
              subject
              expect(JSON.parse(last_response.body)).to eq("errors" => { "some" => "errors" })
            end
          end

          context "when the environment already exists" do
            it "returns a 200" do
              subject
              expect(last_response.status).to be 200
            end

            it "renders the environment" do
              expect(environment_decorator).to receive(:to_json).with(user_options: { base_url: "http://example.org" })
              subject
              expect(last_response.body).to eq environment_json
            end

          end

          context "when the environment does not exist" do
            before do
              allow(Environments::Service).to receive(:find).and_return(nil)
              allow(Environments::Service).to receive(:create).and_return(environment)
            end

            it "creates the environment" do
              expect(Environments::Service).to receive(:create).with(hash_including(environment_attributes))
              subject
            end

            it "returns a 201" do
              subject
              expect(last_response.status).to be 201
            end

            it "renders the environment" do
              expect(environment_decorator).to receive(:to_json).with(user_options: { base_url: "http://example.org" })
              subject
              expect(last_response.body).to eq environment_json
            end
          end
        end
      end
    end
  end
end
