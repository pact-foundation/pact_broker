require 'grape/api'
require 'grape-entity'
require 'pact_broker/logging'
require 'ostruct'



module PactBroker



  class Pacticipant < OpenStruct
    #attr_accessor :name, :repository_url
  end

  module Entities
    class Pacticipant < Grape::Entity
      expose :name
      expose :repository_url
    end
  end

  module Api

    class PacticipantApi < Grape::API

      helpers do
        include PactBroker::Logging
      end

      content_type :html, 'text/html'
      content_type :json, 'application/json' # Grape seems to be upset if we specify HTML without JSON

      default_format :json
      format :json

      resource :pacticipant do
        desc 'rea-rels:links'
        params do
          requires :name, type: String, desc: "Name of the pacticipant"
          optional :repository_url, type: String
        end
        patch ':name' do
          logger.info "Recieved request to patch #{params[:name]} with #{params}"
          pacticipant = Pacticipant.new(name: params[:name], repository_url: params[:repository_url])

          present pacticipant, with: Entities::Pacticipant
        end
      end

    end
  end
end
