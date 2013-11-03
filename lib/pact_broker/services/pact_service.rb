require 'pact_broker/repositories'

module PactBroker

  module Services
    module PactService

      extend self

      extend PactBroker::Repositories

      def find_pact params
        if params[:number] == 'last'
          pact_repository.find_latest_version(params[:consumer], params[:provider])
        else
          raise NotImplementedError
        end
      end

      def create_or_update_pact params
        provider = pacticipant_repository.find_by_name_or_create params[:provider]
        consumer = pacticipant_repository.find_by_name_or_create params[:consumer]
        version = version_repository.find_by_pacticipant_id_and_number_or_create consumer.id, params[:number]

        if pact = pact_repository.find_by_version_and_provider(version.id, provider.id)
          http_status = 200
          pact.update(json_content: params[:json_content])
          return pact, false
        else
          http_status = 201
          pact_repository.create json_content: params[:json_content], version_id: version.id, provider_id: provider.id
          return pact, true
        end

      end

    end
  end
end