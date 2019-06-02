require 'pact_broker/build_http_options'
require 'pact_broker/domain/webhook_request_header'
require 'pact_broker/domain/webhook_execution_result'
require 'pact_broker/logging'
require 'pact_broker/messages'
require 'net/http'
require 'pact_broker/build_http_options'
require 'cgi'
require 'delegate'
require 'rack/utils'
require 'pact_broker/webhooks/webhook_request_logger'

module PactBroker
  module Domain
    class WebhookRequestError < StandardError
      def initialize message, response
        super message
        @response = response
      end
    end

    class WebhookResponseWithUtf8SafeBody < SimpleDelegator
      def body
        if unsafe_body
          unsafe_body.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        else
          unsafe_body
        end
      end

      def unsafe_body
        __getobj__().body
      end

      def unsafe_body?
        unsafe_body != body
      end
    end

    class WebhookRequestWithRedactedHeaders < SimpleDelegator
      def to_hash
        __getobj__().to_hash.each_with_object({}) do | (key, values), new_hash |
          new_hash[key] = redact?(key) ? ["**********"] : values
        end
      end

      def method
        __getobj__().method
      end

      def redact? name
        WebhookRequest::HEADERS_TO_REDACT.any?{ | pattern | name =~ pattern }
      end
    end

    class WebhookRequest

      include PactBroker::Logging

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

      def execute options = {}
        @options = options
        @logs = StringIO.new
        begin
          @response = do_request
        rescue StandardError => e
          @error = e
        end
        do_logging
        WebhookExecutionResult.new(WebhookRequestWithRedactedHeaders.new(http_request), response, logs.string, error)
      end

      def http_request
        @http_request ||= begin
          req = Net::HTTP.const_get(method.capitalize).new(url)
          headers.each_pair { | name, value | req[name] = value }
          req.basic_auth(username, password) if username && username.size > 0
          req.body = body unless body.nil?
          req
        end
      end

      private

      attr_reader :options, :execution_logger, :logs, :webhook_request_logger, :response, :error

      def do_logging
        webhook_request_logger = PactBroker::Webhooks::WebhookRequestLogger.new(logger, Logger.new(logs), uuid, options)
        webhook_request_logger.log_all(self,
          WebhookRequestWithRedactedHeaders.new(http_request),
          response ? WebhookResponseWithUtf8SafeBody.new(response) : nil,
          error
        )
      end

      def do_request
        options = PactBroker::BuildHttpOptions.call(uri)
        req = http_request
        Net::HTTP.start(uri.hostname, uri.port, :ENV, options) do |http|
          http.request req
        end
      end

      def to_s
        "#{method.upcase} #{url}, username=#{username}, password=#{display_password}, headers=#{redacted_headers}, body=#{body}"
      end

      def uri
        @uri ||= URI(url)
      end
    end
  end
end
