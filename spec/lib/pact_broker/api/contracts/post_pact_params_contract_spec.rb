require 'spec_helper'
require 'pact_broker/api/contracts/post_pact_params_contract'
require 'pact_broker/pacts/pact_params'

module PactBroker
  module Api
    module Contracts

      xdescribe PostPactParamsContract do

        let(:json_content) { {'some' => 'json' }.to_json }
        let(:consumer_version_number) { '1.2.3' }
        let(:pact_params) { Pacts::PactParams.new(attributes) }

        subject { PostPactParamsContract.new(pact_params) }

        describe "errors" do

          let(:attributes) { {} }

          before do
            subject.validate
          end

          context "with valid params" do
            let(:attributes) do
              {
                consumer_name: "consumer",
                consumer_name_in_pact: "consumer",
                provider_name: "provider",
                provider_name_in_pact: "provider",
                consumer_version_number: '1.2.3',
                json_content: json_content
              }
            end

            it "is empty" do
              expect(subject.errors.any?).to be false
            end
          end

          context "without an consumer version number" do

            it "returns an error" do
              expect(subject.errors[:base]).to include "Please specify the consumer version number by setting the X-Pact-Consumer-Version header."
            end

          end

          context "with an invalid version number" do
            let(:attributes) { {consumer_version_number: 'blah'} }

            it "returns an error" do
              expect(subject.errors[:base]).to include "X-Pact-Consumer-Version 'blah' is not recognised as a standard semantic version. eg. 1.3.0 or 2.0.4.rc1"
            end
          end

          context "with no consumer name" do
            it "returns an error" do
              expect(subject.errors[:'consumer.name']).to include "was not found at expected path $.consumer.name in the submitted pact file."
            end
          end

          context "with a blank consumer name" do
            let(:attributes) { { consumer_name_in_pact: '' } }
            it "returns an error" do
              expect(subject.errors[:'consumer.name']).to include "cannot be blank."
            end
          end

          context "with no provider name" do
            it "returns an error" do
              expect(subject.errors[:'provider.name']).to include "was not found at expected path $.provider.name in the submitted pact file."
            end
          end

          context "with a blank provider name" do
            let(:attributes) { { provider_name_in_pact: '' } }
            it "returns an error" do
              expect(subject.errors[:'provider.name']).to include "cannot be blank."
            end
          end

        end
      end
    end
  end
end
