require 'pact_broker/api/contracts/put_pact_params_contract'

module PactBroker
  module Api
    module Contracts
      describe PutPactParamsContract do
        before do
          allow(PactBroker.configuration).to receive(:order_versions_by_date).and_return(order_versions_by_date)
        end

        let(:json_content) { {'some' => 'json' }.to_json }
        let(:pact_params) { Pacts::PactParams.new(attributes) }
        let(:order_versions_by_date) { false }

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
            subject.validate(attributes)
          end

          context "with valid params" do

            it "is empty" do
              expect(subject.errors).to be_empty
            end
          end

          context "with a nil consumer version number" do
            let(:attributes) do
              valid_attributes.merge(consumer_version_number: nil)
            end

            it "returns an error" do
              expect(subject.errors[:consumer_version_number]).to include("can't be blank")
            end
          end

          context "with an empty consumer version number" do
            let(:attributes) do
              valid_attributes.merge(consumer_version_number: '')
            end

            it "returns an error" do
              expect(subject.errors[:consumer_version_number]).to include("can't be blank")
            end
          end

          context "with an invalid version number" do
            let(:attributes) do
              valid_attributes.merge(consumer_version_number: 'blah')
            end

            it "returns an error" do
              expect(subject.errors[:consumer_version_number]).to include(/Consumer version number 'blah' cannot be parsed to a version number/)
            end
          end

          context "when order_versions_by_date is true" do
            let(:order_versions_by_date) { true }

            context "with an invalid version number" do
              let(:attributes) do
                valid_attributes.merge(consumer_version_number: 'blah')
              end

              it "does not return an error" do
                expect(subject.errors[:consumer_version_number]).to be_empty
              end
            end
          end

          context "with a consumer name in the pact that does not match the consumer name in the path" do
            let(:attributes) do
              valid_attributes.merge(consumer_name: "another consumer")
            end

            it "returns an error" do
              expect(subject.errors[:'consumer.name']).to include("does not match consumer name in path ('another consumer').")
            end
          end

          context "with a provider name in the pact that does not match the provider name in the path" do
            let(:attributes) do
              valid_attributes.merge(provider_name: "another provider")
            end

            it "returns an error" do
              expect(subject.errors[:'provider.name']).to include("does not match provider name in path ('another provider').")
            end
          end

          context "when the consumer name in the pact is not present" do
            let(:attributes) do
              valid_attributes.tap do | atts |
                atts.delete(:consumer_name_in_pact)
              end
            end

            it "returns no error because I don't want to stop a different CDC from being published" do
              expect(subject.errors).to be_empty
            end
          end

          context "when the provider name in the pact is not present" do
            let(:attributes) do
              valid_attributes.tap do | atts |
                atts.delete(:provider_name_in_pact)
              end
            end

            it "returns no error because I don't want to stop a different CDC from being published" do
              expect(subject.errors).to be_empty
            end
          end
        end
      end
    end
  end
end
