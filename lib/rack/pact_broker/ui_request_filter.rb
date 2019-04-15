# Decides whether this is a request for the UI or a request for the API
# This is only needed so that UI auth logic is not applied to an API request.
# If it was, a 401 or 403 would be returned before the API got a chance
# to actually handle the request, as it would short circuit the cascade
# logic.

module Rack
  module PactBroker
    class UIRequestFilter
      WEB_ASSET_EXTENSIONS = %w[.js .woff .woff2 .css .png .html .map .ttf .ico].freeze
      API_CONTENT_TYPES = %w[application/hal+json application/json text/csv application/yaml].freeze

      def initialize app
        @app = app
      end

      def call env
        if request_for_api(env) || no_accept_header(env) || (accept_all(env) && !is_web_extension(env))
          # send the request on to the next app in the Rack::Cascade
          [404, {},[]]
        else
          @app.call(env)
        end
      end

      private

      def body_is_json(env)
        env['CONTENT_TYPE'] && env['CONTENT_TYPE'].include?("json")
      end

      def request_for_api(env)
        accepts_api_content_type(env) || body_is_api_content_type(env)
      end

      def accepts_api_content_type(env)
        is_api_content_type((env['HTTP_ACCEPT'] && env['HTTP_ACCEPT'].downcase) || "")
      end

      def body_is_api_content_type(env)
        is_api_content_type((env['CONTENT_TYPE'] && env['CONTENT_TYPE'].downcase) || "")
      end

      def is_api_content_type(header)
        API_CONTENT_TYPES.any?{ |content_type| header.include?(content_type) }
      end

      # default curl Accept header
      # Also used by browsers to request various web assets like woff files
      def accept_all(env)
        env['HTTP_ACCEPT'] == "*/*"
      end

      # No browser ever makes a request without an accept header, so it must be an API
      # request if there is no Accept header
      def no_accept_header(env)
        env['HTTP_ACCEPT'] == nil || env['HTTP_ACCEPT'] == ""
      end

      def is_web_extension(env)
        env['PATH_INFO'].end_with?(*WEB_ASSET_EXTENSIONS)
      end
    end
  end
end
