require 'pact_broker/repositories'

module PactBroker

  module Services
    module PactService

      extend self

      extend Repositories
      extend Services

      def find_latest_pact params
        pact_repository.find_latest_pact(params[:consumer_name], params[:provider_name], params[:tag])
      end

      def find_latest_pacts
        pact_repository.find_latest_pacts
      end

      def find_pact params
        pact_repository.find_pact(params[:consumer_name], params[:consumer_version_number], params[:provider_name])
      end

      def create_or_update_pact params
        provider = pacticipant_repository.find_by_name_or_create params[:provider_name]
        consumer = pacticipant_repository.find_by_name_or_create params[:consumer_name]
        consumer_version = version_repository.find_by_pacticipant_id_and_number_or_create consumer.id, params[:consumer_version_number]
        pact = pact_repository.find_by_version_and_provider(consumer_version.id, provider.id)

        if pact
          return update_pact params, pact
        else
          return create_pact params, consumer_version, provider
        end

      end

      def find_all_pacts_between consumer, options
        pact_repository.find_all_pacts_between consumer, options
      end

      def pact_has_changed_since_previous_version? pact
        previous_pact = pact_repository.find_previous_pact pact
        previous_pact && pact.json_content != previous_pact.json_content
      end

      private

      def update_pact params, pact
        previous_json_content = pact.json_content
        pact.update(json_content: params[:json_content])
        if previous_json_content != params[:json_content]
          webhook_service.execute_webhooks pact
        end
        return pact, false
      end

      def create_pact params, version, provider
        pact = pact_repository.create json_content: params[:json_content], version_id: version.id, provider_id: provider.id
        execute_webhooks pact
        return pact, true
      end



      def execute_webhooks pact
        if pact_has_changed_since_previous_version? pact
          webhook_service.execute_webhooks pact
        end
      end

    end
  end
end