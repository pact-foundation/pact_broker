# frozen_string_literal: true

require "uri"
require "pact_broker/messages"


# This class is for https://github.com/pact-foundation/pact_broker/issues/101
# curl -i "http://127.0.0.1:9292/<script>"

module Rack
  module PactBroker
    class InvalidUriProtection
      include ::PactBroker::Messages

      def initialize app
        @app = app
      end

      def call env
        if (uri = valid_uri?(env))
          if (error_message = validate(uri))
            [422, {"Content-Type" => "text/plain"}, [error_message]]
          else
            app.call(env)
          end
        else
          [404, {}, []]
        end
      end

      private

      attr_reader :app

      def valid_uri? env
        begin
          parse(::Rack::Request.new(env).url)
        rescue URI::InvalidURIError, ArgumentError
          nil
        end
      end

      def parse uri
        URI.parse(uri)
      end

      def validate(uri)
        decoded_path = CGI.unescape(uri.path)
        if decoded_path.include?("\n")
          message("errors.new_line_in_url_path")
        elsif decoded_path.include?("\t")
          message("errors.tab_in_url_path")
        end
      end
    end
  end
end
