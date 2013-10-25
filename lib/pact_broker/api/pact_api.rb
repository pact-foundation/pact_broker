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

    class PactApi < Sinatra::Base

      helpers do
        include PactBroker::Logging
        include PactBroker::Repositories

        def put_pact params
          pacticipant = pacticipant_repository.create name: params[:name]
          logger.info "Created pacticipant #{pacticipant}"

          version = version_repository.create(pacticipant_id: pacticipant.id, number: params[:number])
          logger.info "Created version #{version}"

        end

        # def find_or_create_consumer params
        #   pacticipant = pacticipant_repository.find_by_name params[:name]
        #   puts "In pact api, pacticipant #{pacticipant}"
        #   if pacticipant == nil
        #     pacticipant = pacticipant_repository.create name: params[:name]
        #   else
        #     pacticipant
        #   end
        # end

        # def find_or_create_version params
        #   consumer = find_or_create_consumer name: params[:name]

        # end
      end

      helpers Sinatra::JSON
      helpers Sinatra::Param
      register Sinatra::Namespace

      namespace '/pacticipant/:consumer/versions/:number/pacts' do
        put '/:provider' do
          put_pact params
          status 201
        end

        get '/:provider' do
          pact = nil
          pact = pact_repository.find_latest_version(params[:consumer], params[:provider]) if params[:number] == 'last'
          if pact
            status 200
            json pact
          else
            status 404
          end
        end
      end
    end
  end
end
