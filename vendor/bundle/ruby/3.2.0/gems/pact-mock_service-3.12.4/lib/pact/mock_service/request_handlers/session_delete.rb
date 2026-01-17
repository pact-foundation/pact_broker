require 'pact/mock_service/request_handlers/base_administration_request_handler'

module Pact
  module MockService
    module RequestHandlers

      class SessionDelete < BaseAdministrationRequestHandler

        attr_accessor :session

        def initialize name, logger, session
          super name, logger
          @session = session
        end

        def request_path
          '/session'
        end

        def request_method
          'DELETE'
        end

        def respond env
          session.clear_all
          logger.info "Cleared session"
          text_response 'Cleared session'
        end
      end
    end
  end
end
