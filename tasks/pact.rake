require 'pact/tasks'

Pact::VerificationTask.new(:dev) do | pact |
  pact.uri "../pact_broker-client/spec/pacts/pact_broker_client-pact_broker.json"
end

task :set_simplecov_command_to_pact_verify do
  ENV['SIMPLECOV_COMMAND_NAME'] = 'pact:verify'
end

namespace :pact do
  task :prepare => ['db:set_test_env', 'db:prepare:test', 'set_simplecov_command_to_pact_verify',]
  task :verify => :prepare
  task 'verify:at' => :prepare
  task 'verify:dev' => :prepare
end
