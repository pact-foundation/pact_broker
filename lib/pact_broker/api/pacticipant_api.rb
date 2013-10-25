require 'pact_broker/logging'
require 'sequel'
require 'pact_broker/db'
require 'sinatra'
require 'sinatra/json'
require 'sinatra/namespace'
require 'sinatra/param'
require 'pact_broker/models'

module PactBroker


  module Api

    class PacticipantApi < Sinatra::Base

      helpers do
        include PactBroker::Logging
      end

      helpers Sinatra::JSON
      helpers Sinatra::Param
      register Sinatra::Namespace

      namespace '/pacticipant' do
        get '/:name/repository_url' do
          logger.info "GET REPOSTORY URL #{params}"
          pacticipant = PactBroker::Models::Pacticipant.where(:name => params[:name]).first
          logger.info "Found pacticipant #{pacticipant}"
          if pacticipant && pacticipant.repository_url
            content_type 'text/plain'
            pacticipant.repository_url
          else
            status 404
          end
        end

        patch '/:name' do
          #param :repository_url, String, required: false, blank: false

          logger.info "Recieved request to patch #{params[:name]} with #{params}"
          pacticipant = PactBroker::Models::Pacticipant.new(name: params[:name], repository_url: params[:repository_url])
          pacticipant.save
          status 201
          json pacticipant
        end
      end

    end
  end
end
