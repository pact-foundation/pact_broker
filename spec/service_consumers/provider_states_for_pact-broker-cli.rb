require "spec/support/test_data_builder"
require_relative "shared_provider_states"

Pact.provider_states_for "pact-broker-cli" do
  shared_provider_states
  shared_noop_provider_states

end
