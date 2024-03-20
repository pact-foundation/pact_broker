require "pact_broker/integrations/integration"
require "pact_broker/repositories/scopes"

module PactBroker
  module Integrations
    class Repository

      include PactBroker::Repositories::Scopes

      def find(filter_options = {}, pagination_options = {}, eager_load_associations = [])
        query = scope_for(PactBroker::Integrations::Integration).select_all_qualified
        query = query.filter_by_pacticipant(filter_options[:query_string]) if filter_options[:query_string]
        query
          .eager(*eager_load_associations)
          .order(Sequel.desc(:contract_data_updated_at, nulls: :last))
          .all_with_pagination_options(pagination_options)
      end

      def create_for_pact(consumer_id, provider_id)
        if Integration.where(consumer_id: consumer_id, provider_id: provider_id).empty?
          Integration.new(
            consumer_id: consumer_id,
            provider_id: provider_id,
            created_at: Sequel.datetime_class.now,
            contract_data_updated_at: Sequel.datetime_class.now
          ).insert_ignore
        end
        nil
      end

      # Ensure an Integration exists for each consumer/provider pair.
      # @param [Array<Object>] where each object has a consumer and a provider
      def create_for_pacts(objects_with_consumer_and_provider)
        published_integrations = objects_with_consumer_and_provider.collect{ |i| { consumer_id: i.consumer.id, provider_id: i.provider.id } }
        existing_integrations = Sequel::Model.db[:integrations].select(:consumer_id, :provider_id).where(Sequel.|(*published_integrations) ).all
        new_integrations = (published_integrations - existing_integrations).collect{ |i| i.merge(created_at: Sequel.datetime_class.now, contract_data_updated_at: Sequel.datetime_class.now) }
        Integration.dataset.insert_ignore.multi_insert(new_integrations)
      end

      def delete(consumer_id, provider_id)
        Integration.where(consumer_id: consumer_id, provider_id: provider_id).delete
      end

      # Sets the contract_data_updated_at for the integration(s) as specified by the consumer and provider
      # @param [PactBroker::Domain::Pacticipant, nil] consumer the consumer for the integration, or nil if for a provider-only event (eg. Pactflow provider contract published)
      # @param [PactBroker::Domain::Pacticipant] provider the provider for the integration
      def set_contract_data_updated_at(consumer, provider)
        Integration
          .where({ consumer_id: consumer&.id, provider_id: provider.id }.compact )
          .update(contract_data_updated_at: Sequel.datetime_class.now)
      end


      # Sets the contract_data_updated_at for the integrations as specified by an array of objects which each have a consumer and provider
      # @param [Array<Object>] where each object has a consumer and a provider
      def set_contract_data_updated_at_for_multiple_integrations(objects_with_consumer_and_provider)
        consumer_and_provider_ids = objects_with_consumer_and_provider.collect{ | object | [object.consumer.id, object.provider.id] }.uniq
        Integration
          .where([:consumer_id, :provider_id] => consumer_and_provider_ids)
          .update(contract_data_updated_at: Sequel.datetime_class.now)
      end
    end
  end
end
