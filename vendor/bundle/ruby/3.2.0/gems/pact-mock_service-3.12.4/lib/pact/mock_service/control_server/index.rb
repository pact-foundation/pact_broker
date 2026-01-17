module Pact
  module MockService
    module ControlServer
      class Index

        HTTP_X_PACT_MOCK_SERVICE = 'HTTP_X_PACT_MOCK_SERVICE'
        PATH_INFO = 'PATH_INFO'
        INDEX_RESPONSE = [200, {'Content-Type' => 'text/plain'}, ['Control server running']].freeze
        NOT_FOUND_RESPONSE = [404, {}, []].freeze

        def call env
          if is_index_request_with_mock_service_header? env
            INDEX_RESPONSE
          else
            NOT_FOUND_RESPONSE
          end
        end

        def is_index_request_with_mock_service_header? env
          env[HTTP_X_PACT_MOCK_SERVICE] && env[PATH_INFO].chomp("/").size == 0
        end
      end
    end
  end
end
