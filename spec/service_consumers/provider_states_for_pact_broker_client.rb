require 'spec/support/provider_state_builder'

Pact.provider_states_for "Pact Broker Client" do

  provider_state "the 'Pricing Service' does not exist in the pact-broker" do
    no_op
  end

  provider_state "the 'Pricing Service' already exists in the pact-broker" do
    set_up do
      ProviderStateBuilder.new.create_pricing_service.create_pricing_service_version("1.3.0")
    end
  end

  provider_state "an error occurs while publishing a pact" do
    set_up do
      PactBroker::Services::PactService.stub(:create_or_update_pact).and_raise("an error")
    end
  end

  provider_state "a pact between Condor and the Pricing Service exists" do
    set_up do
      ProviderStateBuilder.new
        .create_condor
        .create_condor_version('1.3.0')
        .create_pricing_service
        .create_condor_pricing_service_pact
    end
  end

  provider_state "no pact between Condor and the Pricing Service exists" do
    no_op
  end

  provider_state "the 'Pricing Service' and 'Condor' already exist in the pact-broker, and Condor already has a pact published for version 1.3.0" do
    set_up do
      ProviderStateBuilder.new
        .create_condor
        .create_condor_version('1.3.0')
        .create_pricing_service
        .create_condor_pricing_service_pact
    end
  end

  provider_state "'Condor' already exist in the pact-broker, but the 'Pricing Service' does not" do
    set_up do
      ProviderStateBuilder.new.create_condor
    end
  end

  provider_state "'Condor' exists in the pact-broker" do
    set_up do
      ProviderStateBuilder.new.create_condor.create_condor_version('1.3.0')
    end
  end

  provider_state "'Condor' exists in the pact-broker with version 1.3.0, tagged with 'prod'" do
    set_up do
      ProviderStateBuilder.new
        .create_pacticipant("Condor")
        .create_version('1.3.0')
        .create_tag('prod')
    end
  end

  provider_state "'Condor' does not exist in the pact-broker" do
     no_op
   end

   provider_state "a pact between Condor and the Pricing Service exists for the production version of Condor" do
     set_up do
      ProviderStateBuilder.new
        .create_consumer("Condor")
        .create_consumer_version('1.3.0')
        .create_consumer_version_tag('prod')
        .create_provider("Pricing Service")
        .create_pact
     end
   end

   provider_state "a pacticipant version with production details exists for the Pricing Service" do
     set_up do
       # Your set up code goes here
     end
   end

   provider_state "no pacticipant version exists for the Pricing Service" do
     no_op
   end
end
