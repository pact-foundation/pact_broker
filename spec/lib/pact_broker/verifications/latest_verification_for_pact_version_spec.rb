require 'pact_broker/verifications/latest_verification_for_pact_version'

module PactBroker
  module Verifications
    describe LatestVerificationForPactVersion do
      before do
        td.create_pact_with_hierarchy("Foo", "1", "Bar")
          .create_verification(provider_version: "2")
      end

      subject { LatestVerificationForPactVersion.first }

      its(:"consumer.name") { is_expected.to eq "Foo" }
      its(:"provider.name") { is_expected.to eq "Bar" }
      its(:"provider_version.number") { is_expected.to eq "2" }
    end
  end
end
