require 'spec_helper'
require 'pact_broker/api/resources/pacts'

module PactBroker
  module Api
    module Resources

      describe Pacts do

        describe "POST" do

          let(:pact_service) { PactBroker::Services::PactService }
          let(:pact_content) { load_fixture('consumer-provider.json') }
          let(:path) { "/pacts" }
          let(:response_body_json) { JSON.parse(subject.body) }
          let(:consumer_version_number) { '1.2.3' }
          let(:rack_env) { {'CONTENT_TYPE' => 'application/json', 'HTTP_X_PACT_CONSUMER_VERSION' => consumer_version_number } }
          let(:contract) {  }

          subject { post path, pact_content, rack_env; last_response  }

          context "when the request is invalid" do

            let(:errors) { double('errors', full_messages: ['messages'] ) }

            before do
              allow_any_instance_of(Contracts::PostPactParamsContract).to receive(:validate).and_return(false)
              allow_any_instance_of(Contracts::PostPactParamsContract).to receive(:errors).and_return(errors)
            end

            it "returns a 400 error response" do
              expect(subject).to be_a_json_error_response('messages')
            end

          end

          context "when the request is valid" do

            let(:created_pact) { instance_double(PactBroker::Models::Pact) }
            let(:decorator) { instance_double(PactBroker::Api::Decorators::PactDecorator, to_json: response_json) }
            let(:response_json) { {'some' => 'json' }.to_json }

            before do
              allow(PactBroker::Api::Decorators::PactDecorator).to receive(:new).and_return(decorator)
              allow_any_instance_of(Contracts::PostPactParamsContract).to receive(:validate).and_return(true)
              allow(pact_service).to receive(:create_or_update_pact).and_return(created_pact)
            end

            it "returns a 201 Created" do
              expect(subject.status).to eq 201
            end

            it "returns a Content-Type of application/hal+json" do
              expect(subject.headers['Content-Type']).to eq "application/hal+json"
            end

            it "includes the created pact JSON in the body" do
              expect(PactBroker::Api::Decorators::PactDecorator).to receive(:new).with(created_pact)
              expect(decorator).to receive(:to_json).with(base_url: 'http://example.org')
              expect(subject.body).to eq response_json
            end

            it "sets the Location header" do
              expect(subject.headers["Location"]).to eq "http://example.org/pacts/provider/A%20Provider/consumer/A%20Consumer/version/1.2.3"
            end
          end
        end

      end
    end

  end
end