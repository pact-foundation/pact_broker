require 'pact/mock_service/request_handlers/base_administration_request_handler'
require 'pact/mock_service/interaction_decorator'
require 'pact/shared/json_differ'
require 'pact/mock_service/request_handlers/interaction_post' #Refactor diff message

module Pact
  module MockService
    module RequestHandlers
      class InteractionsPut < BaseAdministrationRequestHandler

        def initialize name, logger, session, pact_specification_version
          super name, logger
          @session = session
          @pact_specification_version = pact_specification_version
        end

        def request_path
          '/interactions'
        end

        def request_method
          'PUT'
        end

        def respond env
          request_body = JSON.load(env['rack.input'].read)
          parsing_options = { pact_specification_version: pact_specification_version }
          interactions = request_body['interactions'].collect { | hash | Interaction.from_hash(hash, parsing_options) }
          begin
            session.set_expected_interactions interactions
            text_response('Registered interactions')
          rescue Pact::Error => e
            text_response(e.message, 500)
          end
        end

        private

        attr_accessor :session, :pact_specification_version

      end
    end
  end
end
