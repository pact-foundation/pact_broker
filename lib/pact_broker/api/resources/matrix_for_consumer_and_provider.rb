require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/matrix_decorator'

module PactBroker
  module Api
    module Resources
      class MatrixForConsumerAndProvider < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET"]
        end

        def resource_exists?
          consumer && provider
        end

        def to_json
          lines = matrix_service.find_for_consumer_and_provider(identifier_from_path)
          PactBroker::Api::Decorators::MatrixPactDecorator.new(lines).to_json(user_options: { base_url: base_url })
        end

        def consumer
          @consumer ||= find_pacticipant(identifier_from_path[:consumer_name], "consumer")
        end

        def provider
          @provider ||= find_pacticipant(identifier_from_path[:provider_name], "provider")
        end

        def find_pacticipant name, role
          pacticipant_service.find_pacticipant_by_name(name).tap do | pacticipant |
            set_json_error_message("No #{role} with name '#{name}' found") if pacticipant.nil?
          end
        end
      end
    end
  end
end