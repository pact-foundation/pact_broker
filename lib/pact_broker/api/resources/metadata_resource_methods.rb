require 'pact_broker/hash_refinements'
require 'pact_broker/pacts/metadata'

module PactBroker
  module Api
    module Resources
      module MetadataResourceMethods
        using PactBroker::HashRefinements

        def pact_params
          @pact_params ||= PactBroker::Pacts::PactParams.from_request(request, maybe_params_with_consumer_version_number.merge(path_info))
        end

        def maybe_params_with_consumer_version_number
          metadata.slice(:consumer_version_number)
        end

        def metadata
          @metadata ||= PactBroker::Pacts::Metadata.parse_metadata(PactBrokerUrls.decode_pact_metadata(identifier_from_path[:metadata]))
        end
      end
    end
  end
end
