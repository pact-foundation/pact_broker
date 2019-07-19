require 'pact_broker/domain/webhook_request_header'
require 'pact_broker/webhooks/render'
require 'cgi'
require 'pact_broker/domain/webhook_request'
require 'pact_broker/string_refinements'

module PactBroker
  module Webhooks
    class WebhookRequestTemplate

      include PactBroker::Logging
      include PactBroker::Messages
      using PactBroker::StringRefinements

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
        @headers = Rack::Utils::HeaderHash.new(attributes[:headers] || {})
        @body = attributes[:body]
        @uuid = attributes[:uuid]
      end

      def build(template_params)
        attributes = {
          method: http_method,
          url: build_url(template_params),
          headers: build_headers(template_params),
          username: build_string(username, template_params),
          password: build_string(password, template_params),
          uuid: uuid,
          body: build_body(template_params)
        }
        PactBroker::Domain::WebhookRequest.new(attributes)
      end

      def description
        "#{http_method.upcase} #{URI(url.gsub(PactBroker::Webhooks::Render::TEMPLATE_PARAMETER_REGEXP, 'placeholder')).host}"
      end

      def display_password
        password.nil? ? nil : "**********"
      end

      def redacted_headers
        headers.each_with_object({}) do | (name, value), new_headers |
          redact = HEADERS_TO_REDACT.any?{ | pattern | name =~ pattern }  && !PactBroker::Webhooks::Render.includes_parameter?(value)
          new_headers[name] = redact ? "**********" : value
        end
      end

      def headers= headers
        @headers = Rack::Utils::HeaderHash.new(headers)
      end


      def to_s
        "#{method.upcase} #{url}, username=#{username}, password=#{display_password}, headers=#{redacted_headers}, body=#{body}"
      end

      private

      def build_url(template_params)
        URI(PactBroker::Webhooks::Render.call(url, template_params){ | value | CGI::escape(value) if !value.nil? } ).to_s
      end

      def build_body(template_params)
        body_string = String === body ? body : body.to_json
        build_string(body_string, template_params)
      end

      def build_headers(template_params)
        headers.each_with_object(Rack::Utils::HeaderHash.new) do | (key, value), new_headers |
          new_headers[key] = build_string(value, template_params)
        end
      end

      def build_string(string, template_params)
        return string if string.nil? || string.blank?
        PactBroker::Webhooks::Render.call(string, template_params)
      end
    end
  end
end
