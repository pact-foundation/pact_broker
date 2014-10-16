require 'spec_helper'
require 'pact_broker/api/contracts/create_pact_request_contract'

module PactBroker
  module Api
    module Contracts

      describe CreatePactRequestContract do

        let(:body) { load_fixture('consumer-provider.json') }
        let(:consumer_version_number) { '1.2.3' }
        let(:headers) { { 'X-Pact-Consumer-Version' => consumer_version_number } }

        let(:request) { Webmachine::Request.new("POST", "/pacts", headers, body)}
        subject { CreatePactRequestContract.new(request) }

        describe "errors" do

          before do
            subject.validate
          end

          context "without an X-Pact-Consumer-Version" do

            let(:headers) { {} }

            it "returns an error" do
              expect(subject.errors[:base]).to include "Please specify the consumer version number by setting the X-Pact-Consumer-Version header."
            end

          end

          context "with an invalid version number" do
            let(:consumer_version_number) { 'blah' }

            it "returns an error" do
              expect(subject.errors[:base]).to include "X-Pact-Consumer-Version 'blah' is not recognised as a standard semantic version. eg. 1.3.0 or 2.0.4.rc1"
            end
          end

          context "with Pact with no consumer name" do
            let(:body) do
              hash = load_json_fixture('consumer-provider.json')
              hash['consumer'].delete('name')
              hash.to_json
            end

            it "returns an error" do
              expect(subject.errors[:'pact.consumer.name']).to include "was not found at expected path $.consumer.name in the submitted pact file."
            end
          end

          context "with Pact with no provider" do
            let(:body) do
              hash = load_json_fixture('consumer-provider.json')
              hash.delete('provider')
              hash.to_json
            end

            it "returns an error" do
              expect(subject.errors[:'pact.provider.name']).to include "was not found at expected path $.provider.name in the submitted pact file."
            end
          end
        end
      end
    end
  end
end
