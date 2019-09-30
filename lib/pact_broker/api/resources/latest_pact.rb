require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'
require 'pact_broker/api/decorators/extended_pact_decorator'

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
          pact
        end

        def to_json
          response.headers['X-Pact-Consumer-Version'] = pact.consumer_version_number
          PactBroker::Api::Decorators::PactDecorator.new(pact).to_json(user_options: { base_url: base_url })
        end

        def to_extended_json
          PactBroker::Api::Decorators::ExtendedPactDecorator.new(pact).to_json(user_options: decorator_context(metadata: identifier_from_path[:metadata]))
        end

        def to_html
          PactBroker.configuration.html_pact_renderer.call(
            pact, {
              base_url: base_url,
              badge_url: "#{resource_url}/badge.svg"
          })
        end

        def pact
          @pact ||= pact_service.find_latest_pact(identifier_from_path)
        end

      end
    end
  end
end
