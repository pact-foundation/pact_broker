require_relative 'base_api'

module PactBroker

  module Api

    class PactApi < BaseApi

      namespace '/pacts' do
        get '/latest' do
          param :consumer, String
          param :provider, String

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
