require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'
require 'pact_broker/api/decorators/extended_pact_decorator'
require 'pact_broker/pacts/metadata'

module PactBroker
  module Api
    module Resources
      class LatestPact < BaseResource
        def content_types_provided
          [
            ["application/hal+json", :to_json],
            ["application/json", :to_json],
            ["text/html", :to_html],
            ["application/vnd.pactbrokerextended.v1+json", :to_extended_json]
          ]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def resource_exists?
          !!pact
        end

        def policy_name
          :'pacts::pact'
        end

        def to_json
          response.headers['X-Pact-Consumer-Version'] = pact.consumer_version_number
          decorator_class(:pact_decorator).new(pact).to_json(decorator_options(metadata: metadata))
        end

        def to_extended_json
          decorator_class(:extended_pact_decorator).new(pact).to_json(decorator_options(metadata: metadata))
        end

        def to_html
          PactBroker.configuration.html_pact_renderer.call(
            pact, {
              base_url: ui_base_url,
              badge_url: "#{resource_url}/badge.svg"
          })
        end

        def pact
          @pact ||= pact_service.find_latest_pact(identifier_from_path)
        end

        def metadata
          @metadata ||= encode_metadata(PactBroker::Pacts::Metadata.build_metadata_for_latest_pact(pact, identifier_from_path))
        end
      end
    end
  end
end
