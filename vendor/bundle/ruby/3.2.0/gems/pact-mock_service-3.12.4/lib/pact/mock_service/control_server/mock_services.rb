require 'rack'
require 'rack/cascade'

module Pact
  module MockService
    module ControlServer
      class MockServices < Rack::Cascade

        def add app
          mock_services << app
          super
        end

        def shutdown
          mock_services.each(&:shutdown)
        end

        private

        def mock_services
          @mock_services ||= []
        end
      end
    end
  end
end
