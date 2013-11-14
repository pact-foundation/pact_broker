require 'webmachine'
require 'pact_broker/services'
require 'pact_broker/api/decorators'

module PactBroker

  module Resources

    class ErrorHandler
      def self.handle_exception e, response
        response.body = {:message => e.message, :backtrace => e.backtrace }.to_json
        response.code = 500
      end
    end

    class BaseResource < Webmachine::Resource

      include PactBroker::Services

      def identifier_from_path
        request.path_info.each_with_object({}) do | pair, hash|
          hash[pair.first] = CGI::unescape(pair.last)
        end
      end

      def request_base_url
        request.uri.to_s.gsub(/#{request.uri.path}$/,'')
      end

      def handle_exception e
        PactBroker::Resources::ErrorHandler.handle_exception(e, response)
      end
    end
  end
end