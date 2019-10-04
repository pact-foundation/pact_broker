require 'pact_broker/integrations/integration'

module PactBroker
  module Integrations
    describe Integration do
      before do
        td.create_pact_with_hierarchy("Foo", "1", "Bar")
          .create_consumer_version("2")
          .create_pact
          .create_verification(provider_version: "3")
          .create_verification(provider_version: "4", number: 2)
      end

      it "has a relationship to the latest pact" do
        integration = Integration.eager(:latest_pact).all.first
        expect(integration.latest_pact.consumer_version_number).to eq "2"
      end

      it "has a relationship to the latest verification via the latest pact" do
        integration = Integration.eager(latest_pact: :latest_verification).all.first
        expect(integration.latest_pact.latest_verification.provider_version_number).to eq "4"
      end

      it "has a verification status" do
        expect(Integration.first.verification_status_for_latest_pact).to be_instance_of(PactBroker::Verifications::Status)
      end
    end
  end
end
