
module PactBroker
  module Api
    module Resources
      class PactVersion < Pact
        include MetadataResourceMethods

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def decorator_options(options = {})
          super(options.merge(consumer_versions: consumer_versions_from_metadata&.reverse))
        end
      end
    end
  end
end
