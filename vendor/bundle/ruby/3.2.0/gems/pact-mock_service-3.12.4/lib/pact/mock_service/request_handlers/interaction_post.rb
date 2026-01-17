require 'pact/mock_service/request_handlers/base_administration_request_handler'
require 'pact/mock_service/session'

module Pact
  module MockService
    module RequestHandlers
      class InteractionPost < BaseAdministrationRequestHandler

        def initialize name, logger, session, pact_specification_version
          super name, logger
          @session = session
          @pact_specification_version = pact_specification_version
        end

        def request_path
          '/interactions'
        end

        def request_method
          'POST'
        end

        def respond env
          request_body = env['rack.input'].read
          parsing_options = { pact_specification_version: pact_specification_version }
          interaction = Interaction.from_hash(JSON.load(request_body), parsing_options) # Load creates the Pact::XXX classes

          begin
            session.add_expected_interaction interaction
            text_response 'Registered interactions'
          rescue ::Pact::Error => e
            text_response e.message, 500
          end

        end

        private

        attr_accessor :session, :pact_specification_version
      end
    end
  end
end
