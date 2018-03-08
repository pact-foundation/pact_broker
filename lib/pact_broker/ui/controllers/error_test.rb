require 'pact_broker/ui/controllers/base_controller'
require 'pact_broker/logging'
require 'pact_broker/error'

module PactBroker
  module UI
    module Controllers
      class ErrorTest < Base
        include PactBroker::Services

        get "/" do
          raise PactBroker::Error.new("Don't panic. This is a test UI error.")
        end
      end
    end
  end
end
