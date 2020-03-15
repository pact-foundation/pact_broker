# frozen_string_literal: true

module Rack
  module PactBroker
    module RequestTarget
      extend self

      WEB_ASSET_EXTENSIONS = %w[.js .woff .woff2 .css .png .html .map .ttf .ico].freeze
      API_CONTENT_TYPES = %w[application/hal+json application/json text/csv application/yaml text/plain].freeze

      def request_for_ui?(env)
        !(request_for_api?(env))
      end

      def request_for_api?(env)
        explicit_request_for_api(env) || no_accept_header(env) || (accept_all(env) && !is_web_extension(env))
      end

      private

      def body_is_json(env)
        env['CONTENT_TYPE']&.include?("json")
      end

      def explicit_request_for_api(env)
        accepts_api_content_type(env) || body_is_api_content_type(env)
      end

      def accepts_api_content_type(env)
        is_api_content_type((env['HTTP_ACCEPT']&.downcase) || "")
      end

      def body_is_api_content_type(env)
        is_api_content_type((env['CONTENT_TYPE']&.downcase) || "")
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
