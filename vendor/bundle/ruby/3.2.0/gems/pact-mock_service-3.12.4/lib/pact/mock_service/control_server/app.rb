require 'pact/consumer/mock_service/rack_request_helper'
require 'pact/mock_service/control_server/require_pacticipant_headers'
require 'pact/mock_service/control_server/index'
require 'pact/mock_service/control_server/mock_services'
require 'pact/mock_service/control_server/mock_service_creator'
require 'rack'
require 'rack/cascade'

module Pact
  module MockService
    module ControlServer
      class App

        include Pact::Consumer::RackRequestHelper

        def initialize options = {}
          @mock_services = mock_services = MockServices.new([])
          @app = Rack::Builder.new {
            run Rack::Cascade.new([
              Index.new,
              Rack::Builder.new {
                use RequirePacticipantHeaders
                run Rack::Cascade.new([
                  mock_services,
                  MockServiceCreator.new(mock_services, options)
                ])
              }
            ])
          }
        end

        def call env
          @app.call(env)
        end

        def shutdown
          @mock_services.shutdown
        end
      end
    end
  end
end
