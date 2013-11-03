require_relative 'base_api'

module PactBroker

  module Api


    class PacticipantApi < BaseApi

      namespace '/pacticipant' do
        get '/:name/repository_url' do
          repository_url = pacticipant_service.find_pacticipant_repository_url_by_pacticipant_name(params[:name])
          if repository_url
            content_type 'text/plain'
            repository_url
          else
            status 404
          end
        end

        patch '/:name' do
          logger.info "Recieved request to patch #{params[:name]} with #{params}"
          pacticipant, created = pacticipant_service.create_or_update_pacticipant(
            name: params[:name],
            repository_url: params[:repository_url]
          )
          created ? status(201) : status(200)
          json pacticipant
        end
      end

    end
  end
end
