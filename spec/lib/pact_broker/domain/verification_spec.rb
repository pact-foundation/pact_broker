require 'pact_broker/domain/verification'

module PactBroker

  module Domain
    describe Verification do
      describe "delete" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_verification_webhook
            .create_verification(provider_version: "2")
            .create_triggered_webhook
            .create_webhook_execution
        end

        it "deletes stuff" do
          Verification.delete
        end
      end

      describe "#save" do
        let!(:verification) do
          TestDataBuilder.new
            .create_pact_with_hierarchy("A", "1", "B")
            .create_verification(test_results: {'some' => 'thing'})
            .and_return(:verification)
        end

        it "saves and loads the test_results" do
          expect(Verification.find(id: verification.id).test_results).to eq({ 'some' => 'thing' })
        end
      end

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
