require 'pact_broker/repositories'

Pact.provider_states_for "Pact Broker Client" do

  provider_state "the 'Pricing Service' does not exist in the pact-broker" do
    no_op
  end

  provider_state "the 'Pricing Service' already exists in the pact-broker" do
    set_up do
      PactBroker::Repositories.pacticipant_repository.create(name: 'Pricing Service', repository_url: 'git@git.realestate.com.au:business-systems/condor.git')
    end
  end

  provider_state "an error occurs while publishing a pact" do
    set_up do
      # Your set up code goes here
    end
  end

  provider_state "a pact between Condor and the Pricing Service exists" do
    set_up do
      consumer = PactBroker::Repositories.pacticipant_repository.create(name: 'Condor', repository_url: 'git@git.realestate.com.au:business-systems/condor.git')
      version = PactBroker::Repositories.version_repository.create(number: '2.0.0', pacticipant_id: consumer.id)
      provider = PactBroker::Repositories.pacticipant_repository.create(name: 'Pricing Service', repository_url: 'git@git.realestate.com.au:business-systems/pricing_service.git')
      PactBroker::Repositories.pact_repository.create(version_id: version.id, provider_id: provider.id, json_content: "[{}]")
    end
  end

  provider_state "no pact between Condor and the Pricing Service exists" do
    no_op
  end

end
