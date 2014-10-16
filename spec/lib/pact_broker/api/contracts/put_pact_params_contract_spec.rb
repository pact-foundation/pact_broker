require 'spec_helper'
require 'pact_broker/api/contracts/put_pact_params_contract'

module PactBroker
  module Api
    module Contracts

      describe PutPactParamsContract do

        let(:json_content) { {'some' => 'json' }.to_json }
        let(:pact_params) { Pacts::PactParams.new(attributes) }

        let(:valid_attributes) do
          {
            consumer_name: "consumer",
            provider_name: "provider",
            consumer_version_number: '1.2.3',
            json_content: json_content,
            consumer_name_in_pact: "consumer",
            provider_name_in_pact: "provider"
          }
        end

        subject { PutPactParamsContract.new(pact_params) }

        describe "errors" do

          let(:attributes) { valid_attributes }

          before do
            subject.validate
          end

          context "with valid params" do

            it "is empty" do
              expect(subject.errors.any?).to be false
            end
          end

          context "with a nil consumer version number" do
            let(:attributes) do
              valid_attributes.merge(consumer_version_number: nil)
            end

            it "returns an error" do
              expect(subject.errors.full_messages).to include "Consumer version number can't be blank"
            end
          end

          context "with an empty consumer version number" do
            let(:attributes) do
              valid_attributes.merge(consumer_version_number: '')
            end

            it "returns an error" do
              expect(subject.errors.full_messages).to include "Consumer version number can't be blank"
            end
          end

          context "with an invalid version number" do
            let(:attributes) { {consumer_version_number: 'blah'} }

            it "returns an error" do
              expect(subject.errors[:base]).to include "Consumer version number 'blah' is not recognised as a standard semantic version. eg. 1.3.0 or 2.0.4.rc1"
            end
          end

          context "with a consumer name in the pact that does not match the consumer name in the path" do

            let(:attributes) do
              valid_attributes.merge(consumer_name: "another consumer")
            end

            it "returns an error" do
              expect(subject.errors.full_messages).to include "Consumer name in pact ('consumer') does not match consumer name in path ('another consumer')."
            end
          end

          context "with a provider name in the pact that does not match the provider name in the path" do

            let(:attributes) do
              valid_attributes.merge(provider_name: "another provider")
            end

            it "returns an error" do
              expect(subject.errors.full_messages).to include "Provider name in pact ('provider') does not match provider name in path ('another provider')."
            end
          end

          context "when the consumer name in the pact is not present" do

            let(:attributes) do
              valid_attributes.tap do | atts |
                atts.delete(:consumer_name_in_pact)
              end
            end

            it "returns no error because I don't want to stop a different CDC from being published" do
              expect(subject.errors.any?).to be false
            end
          end

          context "when the provider name in the pact is not present" do

            let(:attributes) do
              valid_attributes.tap do | atts |
                atts.delete(:provider_name_in_pact)
              end
            end

            it "returns no error because I don't want to stop a different CDC from being published" do
              expect(subject.errors.any?).to be false
            end
          end

        end

      end
    end
  end
end
