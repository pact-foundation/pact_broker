require 'pact_broker/logging'
require 'pact_broker/repositories'
require 'sequel'
require 'pact_broker/db'
require 'sinatra'
require 'sinatra/json'
require 'sinatra/namespace'
require 'sinatra/param'

module PactBroker

  module Api

    class PacticipantApi < Sinatra::Base

      helpers do
        include PactBroker::Logging
        include PactBroker::Repositories
      end

      helpers Sinatra::JSON
      helpers Sinatra::Param
      register Sinatra::Namespace

      namespace '/pacticipant' do
        get '/:name/repository_url' do
          logger.info "GET REPOSTORY URL #{params}"
          pacticipant = pacticipant_repository.find_by_name(params[:name])
          logger.info "Found pacticipant #{pacticipant}"
          if pacticipant && pacticipant.repository_url
            content_type 'text/plain'
            pacticipant.repository_url
          else
            status 404
          end
        end

        patch '/:name' do
          logger.info "Recieved request to patch #{params[:name]} with #{params}"
          pacticipant = pacticipant_repository.find_by_name(params[:name])
          if pacticipant
            pacticipant.update(repository_url: params[:repository_url])
            status 200
          else
            pacticipant = pacticipant_repository.create(name: params[:name], repository_url: params[:repository_url])
            status 201
          end
          json pacticipant
        end
      end

    end
  end
end
