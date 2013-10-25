require 'pact/tasks'

Pact::VerificationTask.new(:dev) do | pact |
  #pact.uri "./pact_broker_client-pact_broker.json"
  pact.uri "../pact_broker-client/spec/pacts/pact_broker_client-pact_broker.json"
end
