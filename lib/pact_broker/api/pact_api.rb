require_relative 'base_api'
require 'pact_broker/api/representors/representable_pact'

module PactBroker

  module Api

    class PactApi < BaseApi

      helpers do
        def create_representable_pact pact
          Representors::RepresentablePact.new(pact)
        end
      end

      namespace '/pacts' do
        get '/latest' do
          param :consumer, String
          param :provider, String

          pacts = pact_service.find_latest_pacts.collect{ | pact | create_representable_pact(pact) }
          pacts.extend(Representors::PactCollectionRepresenter)
          content_type 'application/json+hal;charset=utf-8'
          pacts.to_json

        end
      end

      namespace '/pact/provider/:provider/consumer/:consumer' do

        get '/latest' do
          pact = nil
          pact = pact_service.find_pact(consumer: params[:consumer], provider: params[:provider], number: 'last')
          if pact
            status 200
            headers 'X-Pact-Consumer-Version' => pact.consumer_version_number
            json pact
          else
            status 404
          end
        end

        namespace '/version' do
          put '/:number' do
            pact, created = pact_service.create_or_update_pact(
              provider: params[:provider],
              consumer: params[:consumer],
              number: params[:number],
              json_content: request.body.read)
            created ? status(201) : status(200)
          end

          get '/:number' do
            pact = nil
            pact = pact_service.find_pact(consumer: params[:consumer], provider: params[:provider], consumer_version_number: params[:number])
            if pact
              status 200
              headers 'X-Pact-Consumer-Version' => pact.consumer_version_number
              json pact
            else
              status 404
            end
          end
        end
      end
    end
  end
end
