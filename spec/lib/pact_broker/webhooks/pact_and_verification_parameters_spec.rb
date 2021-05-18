require 'pact_broker/webhooks/pact_and_verification_parameters'
require 'pact_broker/messages'

module PactBroker
  module Webhooks
    describe PactAndVerificationParameters do
      PactAndVerificationParameters::ALL.each do | parameter |
        describe parameter do
          it "has a description in lib/pact_broker/locale/en.yml" do
            expect(PactBroker::Messages.message("messages.webhooks.parameters.#{parameter}", default: nil)).to_not be_nil
          end
        end
      end
    end
  end
end
