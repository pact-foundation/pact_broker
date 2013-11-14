require 'webmachine'
require 'json'

require 'pact_broker/services'
require 'pact_broker/resources/json_resource'
require 'pact_broker/resources/base_url'

module PactBroker

  module Resources

    class LatestPacts < Webmachine::Resource

      include PactBroker::Services
      include PactBroker::Resources::BaseUrl

      #FIX to hal+json
      def content_types_provided
        [["application/hal+json", :to_json]]
      end

      def allowed_methods
        ["GET"]
      end

      def to_json
        generate_json(pact_service.find_latest_pacts)
      end

      def generate_json pacts
        PactBroker::Api::Decorators::PactCollectionRepresenter.new(pacts).to_json(base_url)
      end

      def handle_exception e
        PactBroker::Resources::ErrorHandler.handle_exception(e, response)
      end

    end
  end

end
