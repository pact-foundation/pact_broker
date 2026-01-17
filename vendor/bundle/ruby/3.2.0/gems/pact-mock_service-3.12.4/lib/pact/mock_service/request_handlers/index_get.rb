require 'pact/mock_service/request_handlers/base_administration_request_handler'

module Pact
  module MockService
    module RequestHandlers

      class IndexGet < BaseAdministrationRequestHandler

        def request_path
          ''
        end

        def request_method
          'GET'
        end

        def respond env
          text_response('Mock service running')
        end
      end
    end
  end
end
