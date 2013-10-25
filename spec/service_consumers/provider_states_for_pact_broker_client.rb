require 'pact_broker/repositories'

Pact.provider_states_for "Pact Broker Client" do

  provider_state "the 'Pricing Service' does not exist in the pact-broker" do
    no_op
  end

  provider_state "the 'Pricing Service' already exists in the pact-broker" do
    set_up do
      PactBroker::Repositories.pacticipant_repository.create(:name => 'Pricing Service', :repository_url => 'git@git.realestate.com.au:business-systems/condor.git')
    end
  end

  provider_state "an error occurs while publishing a pact" do
    set_up do
      # Your set up code goes here
    end
  end

  provider_state "a pact between Condor and the Pricing Service exists" do
    set_up do
      PactBroker::Repositories.pacticipant_repository.create(:name => 'Pricing Service', :repository_url => 'git@git.realestate.com.au:business-systems/condor.git')
    end
  end

  provider_state "no pact between Condor and the Pricing Service exists" do
    no_op
  end

end
