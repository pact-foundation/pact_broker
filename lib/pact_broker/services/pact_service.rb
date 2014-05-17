require 'pact_broker/repositories'

module PactBroker

  module Services
    module PactService

      extend self

      extend PactBroker::Repositories

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
        version = version_repository.find_by_pacticipant_id_and_number_or_create consumer.id, params[:consumer_version_number]

        if pact = pact_repository.find_by_version_and_provider(version.id, provider.id)
          pact.update(json_content: params[:json_content])
          return pact, false
        else
          pact = pact_repository.create json_content: params[:json_content], version_id: version.id, provider_id: provider.id
          return pact, true
        end

      end

    end
  end
end