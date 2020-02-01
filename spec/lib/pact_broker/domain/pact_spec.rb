require 'pact_broker/domain/pact'

module PactBroker
  module Domain
    describe Pact do
      describe "latest_verification" do
        context "when it has been set to an object" do
          subject { Pact.new(latest_verification: 'verification') }

          its(:latest_verification) { is_expected.to eq 'verification' }
        end

        context "when it has been set to nil" do
          subject { Pact.new(latest_verification: nil) }

          its(:latest_verification) { is_expected.to eq nil }
        end

        context "when it has not been set" do
          it "raises an error" do
            expect { Pact.new.latest_verification.foo }.to raise_error UnsetAttributeError
          end
        end
      end
    end
  end
end
