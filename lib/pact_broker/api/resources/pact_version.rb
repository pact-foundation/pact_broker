require 'pact_broker/api/resources/pact'

module PactBroker
  module Api
    module Resources
      class PactVersion < Pact
        def allowed_methods
          ["GET", "OPTIONS"]
        end
      end
    end
  end
end
