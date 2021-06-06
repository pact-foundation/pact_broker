require "pact_broker/api/resources/pact"
require "pact_broker/api/resources/metadata_resource_methods"

module PactBroker
  module Api
    module Resources
      class PactVersion < Pact
        include MetadataResourceMethods

        def allowed_methods
          ["GET", "OPTIONS"]
        end
      end
    end
  end
end
