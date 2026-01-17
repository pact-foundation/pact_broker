require 'pact/mock_service/request_handlers/base_administration_request_handler'

module Pact
  module MockService
    module RequestHandlers
      class LogGet < BaseAdministrationRequestHandler

        def request_path
          '/log'
        end

        def request_method
          'GET'
        end

        def respond env
          logger.info "Debug message from client - #{message(env)}"
          text_response
        end

        def message env
          params_hash(env).fetch('msg', [])[0]
        end
      end
    end
  end
end
