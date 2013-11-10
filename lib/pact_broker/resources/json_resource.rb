require 'webmachine'
require 'json'

module PactBroker

  module Resources

    module PathInfo
      def identifier_from_path
        request.path_info.each_with_object({}) do | pair, hash|
          hash[pair.first] = CGI::unescape(pair.last)
        end
      end
    end

    class ErrorHandler
      def self.handle_exception e, response
        response.body = {:message => e.message, :backtrace => e.backtrace }.to_json
        response.code = 500
      end
    end

    class JsonResource < Webmachine::Resource
      def content_types_provided
        [["application/json", :to_json]]
      end

      def content_types_accepted
        [["application/json", :from_json]]
      end

      def handle_exception e
        PactBroker::Resources::ErrorHandler.handle_exception(e, response)
      end
    end
  end
end