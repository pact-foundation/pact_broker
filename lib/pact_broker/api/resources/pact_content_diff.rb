require 'pact_broker/api/resources/base_resource'
require 'pact_broker/pacts/pact_params'
require 'pact_broker/pacts/diff'

module PactBroker
  module Api
    module Resources

      class PactContentDiff < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET"]
        end

        def resource_exists?
          pacticipant_service.find_pacticipant_by_name(consumer_name) &&
            pacticipant_service.find_pacticipant_by_name(provider_name)
        end

        def to_json
          _, body = PactBroker::Pacts::Diff.run pact_params
          response.body = body
        end


        def pact
          @pact ||= pact_service.find_pact(pact_params)
        end

        def pact_params
          @pact_params ||= PactBroker::Pacts::PactParams.from_request request, path_info
        end

      end
    end
  end
end
