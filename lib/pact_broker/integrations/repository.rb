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
      # Using SELECT ... INSERT IGNORE rather than just INSERT IGNORE so that we do not
      # need to lock the table at all when the integrations already exist, which will
      # be the most common use case. New integrations get created incredibly rarely.
      # The INSERT IGNORE is used rather than just INSERT to handle race conditions
      # when requests come in parallel.
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
        set_contract_data_updated_at_for_multiple_integrations([OpenStruct.new(consumer: consumer, provider: provider)])
      end


      # Sets the contract_data_updated_at for the integrations as specified by an array of objects which each have a consumer and provider.
      #
      # The contract_data_updated_at attribute is only ever used for ordering the list of integrations on the index page of the *Pact Broker* UI,
      # so that the most recently updated integrations (the ones you're likely working on) are showed at the top of the first page.
      # There is often contention around updating it however, which can cause deadlocks, and slow down API responses.
      # Because it's not a critical field (eg. it won't change any can-i-deploy results), the easiest way to reduce this contention
      # is to just not update it if the row is locked, because if it is locked, the value of contract_data_updated_at is already
      # going to be a date from a few seconds ago, which is perfectly fine for the purposes for which we are using the value.
      #
      # Notes on SKIP LOCKED:
      # SKIP LOCKED is only supported by Postgres.
      # When executing SELECT ... FOR UPDATE SKIP LOCKED, the SELECT will run immediately, not waiting for any other transactions,
      # and only return rows that are not already locked by another transaction.
      # The FOR UPDATE is required to make it work this way - SKIP LOCKED on its own does not work.
      #
      # @param [Array<Object>] where each object MAY have a consumer and does have a provider (for Pactflow provider contract published there is no consumer)
      def set_contract_data_updated_at_for_multiple_integrations(objects_with_consumer_and_provider)
        consumer_and_provider_ids = objects_with_consumer_and_provider.collect{ | object | { consumer_id: object.consumer&.id, provider_id: object.provider.id }.compact }.uniq

        # MySQL doesn't support an UPDATE with a subquery. FFS. Really need to do a major version release and delete the support code.
        criteria =  if Integration.dataset.supports_skip_locked?
                      integration_ids_to_update = Integration
                                                  .select(:id)
                                                  .where(Sequel.|(*consumer_and_provider_ids))
                                                  .for_update
                                                  .skip_locked
                      { id: integration_ids_to_update }
                    else
                      Sequel.|(*consumer_and_provider_ids)
                    end

        Integration
          .where(criteria)
          .update(contract_data_updated_at: Sequel.datetime_class.now)
      end
    end
  end
end
