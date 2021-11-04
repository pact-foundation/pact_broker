require "pact_broker/integrations/integration"

module PactBroker
  module Integrations
    class Repository

      def create_for_pact(consumer_id, provider_id)
        if Integration.where(consumer_id: consumer_id, provider_id: provider_id).empty?
          Integration.new(consumer_id: consumer_id, provider_id: provider_id).insert_ignore
        end
        nil
      end
    end
  end
end
