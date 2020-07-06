require 'pact_broker/api/resources/base_resource'
require 'pact_broker/pacts/pact_params'
require 'pact_broker/pacts/diff'

module PactBroker
  module Api
    module Resources
      class PactContentDiff < BaseResource
        def content_types_provided
          [["text/plain", :to_text]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def resource_exists?
          consumer && provider
        end

        def to_text
          output = PactBroker::Pacts::Diff.new.process pact_params.merge(base_url: base_url), comparison_pact_params, raw: false
          response.body = output
        end

        def pact
          @pact ||= pact_service.find_pact(pact_params)
        end

        def pact_params
          @pact_params ||= PactBroker::Pacts::PactParams.from_path_info identifier_from_path
        end

        def comparison_pact_params
          if identifier_from_path[:comparison_consumer_version_number] || identifier_from_path[:comparison_pact_version_sha]
            comparison_identifier_from_path = identifier_from_path.merge(
                consumer_version_number: identifier_from_path[:comparison_consumer_version_number],
                pact_version_sha: identifier_from_path[:comparison_pact_version_sha],
                base_url: base_url)
            PactBroker::Pacts::PactParams.from_path_info(comparison_identifier_from_path)
          else
            nil
          end
        end
      end
    end
  end
end
