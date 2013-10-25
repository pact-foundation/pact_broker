require 'pact/tasks'

Pact::VerificationTask.new(:dev) do | pact |
  pact.uri "./pact_broker_client-pact_broker.json"
  #pact.interactions :description => /thing/, :provider_state => /blah/
end