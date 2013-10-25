require 'pact/tasks'

Pact::VerificationTask.new(:dev) do | pact |
  pact.uri "./pact_broker_client-pact_broker.json"
  #pact.interactions :description => /thing/, :provider_state => /blah/
end

namespace :pact do
  task :prepare => [:overwrite_rack_env, 'db:recreate']
  task :verify => :prepare
  task 'verify:at' => :prepare
  task 'verify:dev' => :prepare
end
