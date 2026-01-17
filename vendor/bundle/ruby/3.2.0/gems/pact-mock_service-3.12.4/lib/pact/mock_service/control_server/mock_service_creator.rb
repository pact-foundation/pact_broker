require 'pact/mock_service/spawn'
require 'pact/mock_service/control_server/delegator'
require 'find_a_port'
require 'pact/mock_service/server/wait_for_server_up'

# Create a new MockService on a random port and delegate the incoming request to it

module Pact
  module MockService
    module ControlServer
      class MockServiceCreator

        attr_reader :options

        def initialize mock_services, options
          @mock_services = mock_services
          @options = options
        end

        def call env
          consumer_name = env['HTTP_X_PACT_CONSUMER']
          provider_name = env['HTTP_X_PACT_PROVIDER']
          port = FindAPort.available_port
          mock_service = Pact::MockService::Spawn.(consumer_name, provider_name, options[:host] || 'localhost', port, options)
          delegator = Delegator.new(mock_service, consumer_name, provider_name)
          @mock_services.add(delegator)
          delegator.call(env)
        end
      end
    end
  end
end
