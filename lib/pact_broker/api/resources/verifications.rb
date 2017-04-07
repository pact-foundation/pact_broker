require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'

module PactBroker
  module Api
    module Resources

      class Verifications < BaseResource

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["POST"]
        end

        def post_is_create?
          true
        end

        def create_path
          new_verification_url(pact_params, next_verification_number, base_url)
        end

        def from_json
          #pact_service.create(next_verification_number, pact, decorator here)
          true
        end

        def resource_exists?
          !!pact
        end

        private

        def pact
          @pact ||= pact_service.find_pact(pact_params)
        end

        def pact_params
          @pact_params ||= PactBroker::Pacts::PactParams.from_request request, path_info
        end

        def next_verification_number
          @next_verification_number ||= verification_service.next_number_for(pact)
        end
      end
    end
  end
end
