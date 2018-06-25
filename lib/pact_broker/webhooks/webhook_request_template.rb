require 'pact_broker/domain/webhook_request_header'
require 'pact_broker/webhooks/render'
require 'cgi'
require 'pact_broker/domain/webhook_request'

module PactBroker
  module Webhooks
    class WebhookRequestTemplate

      include PactBroker::Logging
      include PactBroker::Messages
      HEADERS_TO_REDACT = [/authorization/i, /token/i]

      attr_accessor :method, :url, :headers, :body, :username, :password, :uuid

      # Reform gets confused by the :method method, as :method is a standard
      # Ruby method.
      alias_method :http_method, :method

      def initialize attributes = {}
        @method = attributes[:method]
        @url = attributes[:url]
        @username = attributes[:username]
        @password = attributes[:password]
        @headers = attributes[:headers] || {}
        @body = attributes[:body]
        @uuid = attributes[:uuid]
      end

      def build(context)
        attributes = {
          method: http_method,
          url: build_url(context[:pact], context[:verification]),
          headers: headers,
          username: username,
          password: password,
          uuid: uuid,
          body: build_body(context[:pact], context[:verification])
        }
        PactBroker::Domain::WebhookRequest.new(attributes)
      end

      def build_url(pact, verification)
        URI(PactBroker::Webhooks::Render.call(url, pact, verification){ | value | CGI::escape(value) if !value.nil? } ).to_s
      end

      def build_body(pact, verification)
        PactBroker::Webhooks::Render.call(String === body ? body : body.to_json, pact, verification)
      end

      def description
        "#{http_method.upcase} #{URI(url.gsub(PactBroker::Webhooks::Render::TEMPLATE_PARAMETER_REGEXP, 'placeholder')).host}"
      end

      def display_password
        password.nil? ? nil : "**********"
      end

      def redacted_headers
        headers.each_with_object({}) do | (name, value), new_headers |
          redact = HEADERS_TO_REDACT.any?{ | pattern | name =~ pattern }
          new_headers[name] = redact ? "**********" : value
        end
      end

      private

      def to_s
        "#{method.upcase} #{url}, username=#{username}, password=#{display_password}, headers=#{redacted_headers}, body=#{body}"
      end
    end
  end
end
