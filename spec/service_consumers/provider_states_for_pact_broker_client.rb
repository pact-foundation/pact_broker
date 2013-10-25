require_relative 'pact_helper'


Pact.provider_states_for "Pact Broker Client" do
  provider_state "the 'Pricing Service' does not exist in the pact-broker" do
    no_op
  end
end
