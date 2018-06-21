require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/pacticipant_collection_decorator'

module PactBroker
  module Api
    module Resources
      class PacticipantsForLabel < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def to_json
          generate_json(pacticipant_service.find identifier_from_path )
        end

        def generate_json pacticipants
          PactBroker::Api::Decorators::PacticipantCollectionDecorator.new(pacticipants).to_json(user_options: { base_url: base_url })
        end
      end
    end
  end
end
