require "pact_broker/build_http_options"
require "pact_broker/webhooks/webhook_execution_result"
require "pact_broker/logging"
require "pact_broker/messages"
require "net/http"
require "pact_broker/build_http_options"
require "cgi"
require "delegate"
require "rack/utils"
require "pact_broker/webhooks/webhook_request_logger"
require "pact_broker/configuration"

module PactBroker
  module Domain
    class WebhookRequest

      include PactBroker::Logging

      HEADERS_TO_REDACT = [/authorization/i, /token/i]

      attr_accessor :method, :url, :headers, :body, :username, :password, :uuid

      # Reform gets confused by the :method method, as :method is a standard
      # Ruby method.
      alias_method :http_method, :method

      def initialize attributes = {}
        attributes.each do | (name, value) |
          instance_variable_set("@#{name}", value) if respond_to?(name)
        end
        @headers = attributes[:headers] || {}
      end

      def description
        "#{method.upcase} #{URI(url).host}"
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

      def execute
        options = PactBroker::BuildHttpOptions.call(uri).merge(read_timeout: 15, open_timeout: 15)
        req = http_request
        Net::HTTP.start(uri.hostname, uri.port, :ENV, options) do |http|
          http.request req
        end
      end

      def http_request
        @http_request ||= begin
          req = Net::HTTP.const_get(method.capitalize).new(uri.request_uri)
          req.delete("accept-encoding")
          req["user-agent"] = PactBroker.configuration.user_agent
          headers.each_pair { | name, value | req[name] = value }
          req.basic_auth(username, password) if username && username.size > 0
          req.body = body unless body.nil?
          req
        end
      end

      private

      def to_s
        "#{method.upcase} #{url}, username=#{username}, password=#{display_password}, headers=#{redacted_headers}, body=#{body}"
      end

      def uri
        @uri ||= URI(url)
      end
    end
  end
end
