require 'pact_broker/repositories'
require 'pact_broker/webhooks/repository'
require 'pact_broker/webhooks/service'
require 'pact_broker/pacts/repository'
require 'pact_broker/pacts/service'
require 'pact_broker/pacticipants/repository'
require 'pact_broker/pacticipants/service'
require 'pact_broker/versions/repository'
require 'pact_broker/versions/service'
require 'pact_broker/tags/repository'
require 'pact_broker/tags/service'
require 'pact_broker/domain'
require 'json'

class ProviderStateBuilder

  include PactBroker::Repositories

  attr_reader :pacticipant
  attr_reader :consumer
  attr_reader :provider
  attr_reader :webhook

  def create_pricing_service
    @pricing_service_id = pacticipant_repository.create(:name => 'Pricing Service', :repository_url => 'git@git.realestate.com.au:business-systems/pricing-service').save(raise_on_save_failure: true).id
    self
  end

  def create_contract_proposal_service
    @contract_proposal_service_id = pacticipant_repository.create(:name => 'Contract Proposal Service', :repository_url => 'git@git.realestate.com.au:business-systems/contract-proposal-service').save(raise_on_save_failure: true).id
    self
  end

  def create_contract_proposal_service_version number
    @contract_proposal_service_version_id = version_repository.create(number: number, pacticipant_id: @contract_proposal_service_id).id
    self
  end

  def create_contract_email_service
    @contract_email_service_id = pacticipant_repository.create(:name => 'Contract Email Service', :repository_url => 'git@git.realestate.com.au:business-systems/contract-email-service').save(raise_on_save_failure: true).id
    self
  end

  def create_contract_email_service_version number
    @contract_email_service_version_id = version_repository.create(number: number, pacticipant_id: @contract_email_service_id).id
    self
  end

  def create_ces_cps_pact
    @pact_id = pact_repository.create(version_id: @contract_email_service_version_id, consumer_id: @contract_email_service_id, provider_id: @contract_proposal_service_id, json_content: default_json_content).id
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

  def create_condor_pricing_service_pact
    @pact_id = pact_repository.create(version_id: @condor_version_id, consumer_id: @condor_id, provider_id: @pricing_service_id, json_content: default_json_content).id
    self
  end

  def create_pact_with_hierarchy consumer_name, consumer_version, provider_name, json_content = default_json_content
    provider = PactBroker::Domain::Pacticipant.create(:name => provider_name)
    consumer = PactBroker::Domain::Pacticipant.create(:name => consumer_name)
    version = PactBroker::Domain::Version.create(:number => consumer_version, :pacticipant => consumer)
    PactBroker::Pacts::Repository.new.create(version_id: version.id, consumer_id: consumer.id, provider_id: provider.id, json_content: json_content)
  end

  def create_version_with_hierarchy pacticipant_name, pacticipant_version
    pacticipant = PactBroker::Domain::Pacticipant.create(:name => pacticipant_name)
    version = PactBroker::Domain::Version.create(:number => pacticipant_version, :pacticipant => pacticipant)
    PactBroker::Domain::Version.find(id: version.id) # Get version with populated order
  end

  def create_tag_with_hierarchy pacticipant_name, pacticipant_version, tag_name
    version = create_version_with_hierarchy pacticipant_name, pacticipant_version
    PactBroker::Domain::Tag.create(name: tag_name, version: version)
  end

  def create_pacticipant pacticipant_name
    @pacticipant = PactBroker::Domain::Pacticipant.create(:name => pacticipant_name)
    self
  end

  def create_consumer consumer_name
    create_pacticipant consumer_name
    @consumer = @pacticipant
    self
  end

  def create_provider provider_name
    create_pacticipant provider_name
    @provider = @pacticipant
    self
  end

  def create_version version_number
    @version = PactBroker::Domain::Version.create(:number => version_number, :pacticipant => @pacticipant)
    self
  end

  def create_consumer_version version_number
    @consumer_version = PactBroker::Domain::Version.create(:number => version_number, :pacticipant => @consumer)
    self
  end

  def create_tag tag_name
    @tag = PactBroker::Domain::Tag.create(name: tag_name, version: @version)
    self
  end

  def create_consumer_version_tag tag_name
    @tag = PactBroker::Domain::Tag.create(name: tag_name, version: @consumer_version)
    self
  end

  def create_pact json_content = default_json_content
    @pact = PactBroker::Pacts::Repository.new.create(version_id: @consumer_version.id, consumer_id: @consumer.id, provider_id: @provider.id, json_content: json_content)
    self
  end

  def revise_pact json_content = nil
    json_content = json_content ? json_content : {random: rand}.to_json
    @pact = PactBroker::Pacts::Repository.new.update(@pact.id, json_content: json_content)
    self
  end

  def create_webhook
    request = PactBroker::Domain::WebhookRequest.new(method: 'POST', url: 'http://example.org', headers: {'Content-Type' => 'application/json'})
    @webhook = PactBroker::Webhooks::Repository.new.create PactBroker::Webhooks::Service.next_uuid, PactBroker::Domain::Webhook.new(request: request), @consumer, @provider
    self
  end

  private

  def default_json_content
    {
      "consumer"     => {
         "name" => "Condor"
       },
       "provider"     => {
         "name" => "Pricing Service"
       },
       "interactions" => [],
       "random": rand

     }.to_json
   end

end