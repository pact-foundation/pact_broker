require 'pact_broker/repositories'

module PactBroker

  module Services
    class PacticipantService

      extend PactBroker::Repositories

      def self.find_pacticipant_repository_url_by_pacticipant_name name
        pacticipant = pacticipant_repository.find_by_name(name)
        if pacticipant && pacticipant.repository_url
          pacticipant.repository_url
        else
          nil
        end
      end

      def self.create_or_update_pacticipant params
        pacticipant = pacticipant_repository.find_by_name(params[:name])
        if pacticipant
          pacticipant.update(repository_url: params[:repository_url])
          return pacticipant, false
        else
          pacticipant = pacticipant_repository.create(name: params[:name], repository_url: params[:repository_url])
          return pacticipant, true
        end
      end
    end
  end
end