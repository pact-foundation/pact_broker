require 'webmachine'
require 'pact_broker/services'
require 'pact_broker/api/decorators'
require 'pact_broker/logging'
require 'pact_broker/api/pact_broker_urls'

module PactBroker::Api

  module Resources


    class ErrorHandler

      include PactBroker::Logging

      def self.handle_exception e, response
        logger.error e
        logger.error e.backtrace
        response.body = {:message => e.message, :backtrace => e.backtrace }.to_json
        response.code = 500
      end
    end

    class BaseResource < Webmachine::Resource

      include PactBroker::Services
      include PactBroker::Api::PactBrokerUrls

      def identifier_from_path
        request.path_info.each_with_object({}) do | pair, hash|
          hash[pair.first] = CGI::unescape(pair.last)
        end
      end

      def resource_url
        request.uri.to_s.gsub(/#{request.uri.path}$/,'')
      end

      def handle_exception e
        PactBroker::Api::Resources::ErrorHandler.handle_exception(e, response)
      end

      def params
        JSON.parse(request.body.to_s, symbolize_names: true)
      end
    end
  end
end