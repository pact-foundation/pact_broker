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

          if params[:consumer] || params[:provider]
            pact = nil
            pact = pact_service.find_pact(consumer: params[:consumer], provider: params[:provider], number: 'last')
            if pact
              status 200
              headers 'X-Pact-Consumer-Version' => pact.consumer_version_number
              json pact
            else
              status 404
            end
          else
            pacts = pact_service.find_latest_pacts.collect{ | pact | create_representable_pact(pact) }
            pacts.extend(Representors::PactCollectionRepresenter)
            content_type 'application/json+hal;charset=utf-8'
            pacts.to_json
          end

        end
      end

      namespace '/pacticipants/:consumer/versions/:number/pacts' do
        put '/:provider' do
          pact, created = pact_service.create_or_update_pact(
            provider: params[:provider],
            consumer: params[:consumer],
            number: params[:number],
            json_content: request.body.read)
          created ? status(201) : status(200)
        end

        # Deprecate???
        get '/:provider' do
          pact = nil
          pact = pact_service.find_pact(consumer: params[:consumer], provider: params[:provider], number: params[:number])
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
