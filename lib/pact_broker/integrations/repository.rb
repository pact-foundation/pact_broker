require "pact_broker/integrations/integration"

module PactBroker
  module Integrations
    class Repository
      def create_for_pact(consumer_id, provider_id)
        if Integration.where(consumer_id: consumer_id, provider_id: provider_id).empty?
          Integration.new(
            consumer_id: consumer_id,
            provider_id: provider_id,
            created_at: Sequel.datetime_class.now
          ).insert_ignore
        end
        nil
      end

      def delete(consumer_id, provider_id)
        Integration.where(consumer_id: consumer_id, provider_id: provider_id).delete
      end

      def set_contract_data_updated_at(consumer, provider)
        Integration
          .where({ consumer_id: consumer&.id, provider_id: provider.id }.compact )
          .update(contract_data_updated_at: Sequel.datetime_class.now)
      end
    end
  end
end
