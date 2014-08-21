require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'

module PactBroker
  module Api
    module Resources

      class LatestPact < BaseResource

        def content_types_provided
          [["application/json", :to_json],
          ["text/html", :to_html]]
        end

        def allowed_methods
          ["GET"]
        end

        def resource_exists?
          @pact = pact_service.find_latest_pact(identifier_from_path)
          @pact != nil
        end

        def to_json
          response.headers['X-Pact-Consumer-Version'] = @pact.consumer_version_number
          PactBroker::Api::Decorators::PactDecorator.new(@pact).to_json(base_url: base_url)
        end

        def to_html
          PactBroker.configuration.html_pact_renderer.call(@pact)
        end

      end
    end
  end
end
