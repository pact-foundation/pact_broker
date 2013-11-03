require_relative 'base_api'

module PactBroker

  module Api

    class PactApi < BaseApi

      namespace '/pacticipant/:consumer/versions/:number/pacts' do
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
