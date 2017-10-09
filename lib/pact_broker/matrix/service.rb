require 'pact_broker/repositories'

module PactBroker
  module Matrix
    module Service
      extend self

      extend PactBroker::Repositories

      def find params
        matrix_repository.find params[:consumer_name], params[:provider_name]
      end

      def find_compatible_pacticipant_versions criteria
        matrix_repository.find_compatible_pacticipant_versions criteria
      end
    end
  end
end
