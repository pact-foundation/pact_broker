require 'pact_broker/domain/verification'

module PactBroker

  module Domain
    describe Verification do

      describe "#consumer" do
        let!(:consumer) do
          TestDataBuilder.new
            .create_consumer
            .create_provider
            .create_consumer_version
            .create_pact
            .create_verification
            .and_return(:consumer)
        end

        it "returns the consumer for the verification" do
          expect(Verification.order(:id).first.consumer).to eq consumer
        end
      end

      describe "#provider" do
        let!(:provider) do
          TestDataBuilder.new
            .create_consumer
            .create_provider
            .create_consumer_version
            .create_pact
            .create_verification
            .and_return(:provider)
        end

        it "returns the provider for the verification" do
          expect(Verification.order(:id).first.provider).to eq provider
        end
      end
    end
  end
end
