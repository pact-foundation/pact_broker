# Decides whether this is a browser request or a request for the API
module Rack
  module PactBroker
    class AcceptsHtmlFilter
      def initialize app
        @app = app
      end

      def call env
        if accepts_web_content_types_and_not_api_media env
          @app.call(env)
        else
          [404, {},[]]
        end
      end

      def accepts_web_content_types_and_not_api_media env
        accept = env['HTTP_ACCEPT'] || ''
        accepts_web_content_types(accept) && !accepts_api_content_types(accept)
      end

      def accepts_web_content_types(accept)
        accept.include?("*/*") || accept.include?("html") || accept.include?("text/css") || accept.include?("text/javascript")
      end

      def accepts_api_content_types accept
        accept.include?("json") || accept.include?("csv")
      end
    end
  end
end
