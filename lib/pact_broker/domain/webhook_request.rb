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
        @execution_logger = Logger.new(logs)
        @webhook_request_logger = PactBroker::Webhooks::WebhookRequestLogger.new(logger, execution_logger, uuid, options)
        begin
          execute_and_build_result
        rescue StandardError => e
          handle_error_and_build_result(e)
        end
      end

      private

      attr_reader :options, :execution_logger, :logs, :webhook_request_logger

      def execute_and_build_result
        webhook_request_logger.log_request(WebhookRequestWithRedactedHeaders.new(http_request), self)
        response = do_request
        webhook_request_logger.log_response(response)
        result = WebhookExecutionResult.new(WebhookRequestWithRedactedHeaders.new(http_request), response, logs.string)
        webhook_request_logger.log_completion_message(result.success?)
        result
      end

      def handle_error_and_build_result e
        webhook_request_logger.log_error(e)
        webhook_request_logger.log_completion_message(false)
        WebhookExecutionResult.new(WebhookRequestWithRedactedHeaders.new(http_request), nil, logs.string, e)
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

      def do_request
        options = PactBroker::BuildHttpOptions.call(uri)
        req = http_request
        response = Net::HTTP.start(uri.hostname, uri.port, :ENV, options) do |http|
          http.request req
        end
        WebhookResponseWithUtf8SafeBody.new(response)
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
