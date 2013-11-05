require 'pact_broker/repositories'

class ProviderStateBuilder

  include PactBroker::Repositories

  def create_pricing_service
    @pricing_service_id = pacticipant_repository.create(:name => 'Pricing Service', :repository_url => 'git@git.realestate.com.au:business-systems/pricing-service').save(raise_on_save_failure: true).id
    self
  end

  def create_condor
    @condor_id = pacticipant_repository.create(:name => 'Condor').save(raise_on_save_failure: true).id
    self
  end

  def create_condor_version number
    @condor_version_id = version_repository.create(number: number, pacticipant_id: @condor_id).id
    self
  end

  def create_pricing_service_version number
    @pricing_service_version_id = version_repository.create(number: number, pacticipant_id: @pricing_service_id).id
    self
  end

  def create_pact
    @pact_id = pact_repository.create(version_id: @condor_version_id, provider_id: @pricing_service_id, json_content: json_content).id
    self
  end

  private

  def json_content
    json_content = {
      "consumer"     => {
         "name" => "Condor"
       },
       "provider"     => {
         "name" => "Pricing Service"
       },
       "interactions" => []
     }.to_json
   end

end



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
        .create_pact
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
        .create_pact
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

  provider_state "'Condor' does not exist in the pact-broker" do
     no_op
   end

   provider_state "a pact between Condor and the Pricing Service exists for the production version of Condor" do
     set_up do
       # Your set up code goes here
     end
   end

   provider_state "a version with production details exists for the Pricing Service" do
     set_up do
       # Your set up code goes here
     end
   end

   provider_state "no version exists for the Pricing Service" do
     no_op
   end
end
