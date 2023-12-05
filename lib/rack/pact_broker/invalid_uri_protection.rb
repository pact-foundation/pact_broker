# frozen_string_literal: true

require "uri"
require "pact_broker/messages"


# This class is for https://github.com/pact-foundation/pact_broker/issues/101
# curl -i "http://127.0.0.1:9292/<script>"

module Rack
  module PactBroker
    class InvalidUriProtection
      include ::PactBroker::Messages

      CONSECUTIVE_SLASH = /\/{2,}/

      def initialize app
        @app = app
      end

      def call env
        if (uri = valid_uri?(env))
          if (error_message = validate(uri))
            [422, headers, [body(env, error_message, "Unprocessable", "invalid-request-parameter-value", 422)]]
          else
            app.call(env)
          end
        else
          [404, headers, [body(env, "Empty path component found", "Not Found", "not-found", 404)]]
        end
      end

      private

      attr_reader :app

      def valid_uri? env
        begin
          uri = parse(::Rack::Request.new(env).url)
          return nil if CONSECUTIVE_SLASH.match(uri.path)
          uri
        rescue URI::InvalidURIError, ArgumentError
          nil
        end
      end

      def parse uri
        URI.parse(uri)
      end

      def validate(uri)
        decoded_path = URI.decode_www_form_component(uri.path)
        if decoded_path.include?("\n")
          message("errors.new_line_in_url_path")
        elsif decoded_path.include?("\t")
          message("errors.tab_in_url_path")
        end
      end

      def headers
        {"Content-Type" => "application/problem+json"}
      end

      def body(env, detail, title, type, status)
        env["pactbroker.application_context"]
          .decorator_configuration
          .class_for(:custom_error_problem_json_decorator)
          .new(detail: detail, title: title, type: type, status: status)
          .to_json(user_options: { base_url: env["pactbroker.base_url"] })
      end
    end
  end
end
