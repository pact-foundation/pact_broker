Pact.provider_states_for "Pact Broker Client" do
  provider_state "the 'Pricing Service' does not exist in the pact-broker" do
    no_op
  end

  provider_state "the 'Pricing Service' already exists in the pact-broker" do
    set_up do
      PactBroker::Models::Pacticipant.new(:name => 'Pricing Service', :repository_url => 'git@git.realestate.com.au:business-systems/condor.git').save(raise_on_save_failure: true)
    end
  end

  provider_state "an error occurs while publishing a pact" do
    set_up do
      # Your set up code goes here
    end
  end

end
