require_relative 'base_api'
require_relative 'representors'

module PactBroker
  module Api

    class PacticipantApi < BaseApi

      get "/pacticipants" do
        pacticipants = pacticipant_service.find_all_pacticipants
        pacticipants.extend(Representors::PacticipantCollectionRepresenter)
        content_type 'application/json+hal;charset=utf-8'
        pacticipants.to_json
      end

      namespace '/pacticipants' do

        get '/:name' do
          pacticipant = pacticipant_service.find_pacticipant_by_name(params[:name])
          if pacticipant
            pacticipant.extend(Representors::PacticipantRepresenter)
            content_type 'application/json+hal;charset=utf-8'
            pacticipant.to_json
          else
            status 404
          end
        end

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
          pacticipant.extend(Representors::PacticipantRepresenter)
          content_type 'application/json+hal;charset=utf-8'
          pacticipant.to_json
        end
      end

    end
  end
end
