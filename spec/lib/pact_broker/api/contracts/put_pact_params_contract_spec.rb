require "pact_broker/api/contracts/put_pact_params_contract"
require "pact_broker/pacts/pact_params"

module PactBroker
  module Api
    module Contracts
      describe PutPactParamsContract do
        include PactBroker::Test::ApiContractSupport

        before do
          allow(PactBroker.configuration).to receive(:order_versions_by_date).and_return(order_versions_by_date)
        end

        let(:json_content) { {"some" => "json" }.to_json }
        let(:pact_params) { Pacts::PactParams.new(attributes).to_hash_for_validation }
        let(:order_versions_by_date) { false }

        let(:valid_attributes) do
          {
            consumer_name: "consumer",
            provider_name: "provider",
            consumer_version_number: "1.2.3",
            json_content: json_content,
            consumer_name_in_pact: "consumer",
            provider_name_in_pact: "provider"
          }
        end

        subject { format_errors_the_old_way(PutPactParamsContract.call(pact_params)) }

        describe "errors" do
          let(:attributes) { valid_attributes }

          context "with valid params" do

            it "is empty" do
              expect(subject).to be_empty
            end
          end

          context "with a blank consumer version number" do
            let(:attributes) do
              valid_attributes.merge(consumer_version_number: " ")
            end

            it "returns an error" do
              expect(subject[:consumer_version_number].first).to include("blank")
            end
          end

          context "with an empty consumer version number" do
            let(:attributes) do
              valid_attributes.merge(consumer_version_number: "")
            end

            it "returns an error" do
              expect(subject[:consumer_version_number].first).to include("filled")
            end
          end

          context "with an invalid version number" do
            let(:attributes) do
              valid_attributes.merge(consumer_version_number: "blah")
            end

            it "returns an error" do
              expect(subject[:consumer_version_number]).to include(/Version number 'blah' cannot be parsed to a version number/)
            end
          end

          context "when order_versions_by_date is true" do
            let(:order_versions_by_date) { true }

            context "with an invalid version number" do
              let(:attributes) do
                valid_attributes.merge(consumer_version_number: "blah")
              end

              it "does not return an error" do
                expect(subject).to be_empty
              end
            end
          end

          context "with a consumer name in the pact that does not match the consumer name in the path" do
            let(:attributes) do
              valid_attributes.merge(consumer_name: "another consumer")
            end

            it "returns an error" do
              expect(subject[:'consumer.name']).to include("name in pact 'consumer' does not match name in URL path 'another consumer'.")
            end
          end

          context "with a provider name in the pact that does not match the provider name in the path" do
            let(:attributes) do
              valid_attributes.merge(provider_name: "another provider")
            end

            it "returns an error" do
              expect(subject[:'provider.name']).to include("name in pact 'provider' does not match name in URL path 'another provider'.")
            end
          end

          context "when the consumer name in the pact is not present" do
            let(:attributes) do
              valid_attributes.tap do | atts |
                atts.delete(:consumer_name_in_pact)
              end
            end

            it "returns no error because I don't want to stop a different CDC from being published" do
              expect(subject).to be_empty
            end
          end

          context "when the provider name in the pact is not present" do
            let(:attributes) do
              valid_attributes.tap do | atts |
                atts.delete(:provider_name_in_pact)
              end
            end

            it "returns no error because I don't want to stop a different CDC from being published" do
              expect(subject).to be_empty
            end
          end
        end
      end
    end
  end
end
