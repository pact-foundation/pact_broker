require 'pact_broker/verifications/repository'

module PactBroker
  module Verifications
    describe Repository do

      describe "#verification_count_for_pact" do
        let!(:pact_1) { ProviderStateBuilder.new.create_pact_with_hierarchy }
        let!(:pact_2) { ProviderStateBuilder.new.create_pact_with_hierarchy "Foo", "1.3.4", "Bar" }
        let!(:verification_1) { PactBroker::Domain::Verification.new(pact_id: pact_1.id, success: true).save }
        let!(:verification_2) { PactBroker::Domain::Verification.new(pact_id: pact_1.id, success: true).save }
        let!(:verification_3) { PactBroker::Domain::Verification.new(pact_id: pact_2.id, success: true).save }

        it "returns the number of verifications for the given pact" do
          expect(Repository.new.verification_count_for_pact(pact_1)).to eq 2
        end
      end
    end
  end
end
