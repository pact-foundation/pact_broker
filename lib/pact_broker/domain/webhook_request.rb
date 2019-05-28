require 'pact_broker/build_http_options'
require 'pact_broker/domain/webhook_request_header'
require 'pact_broker/domain/webhook_execution_result'
require 'pact_broker/logging'
require 'pact_broker/messages'
require 'net/http'
require 'pact_broker/webhooks/render'
require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/build_http_options'
require 'cgi'
require 'delegate'
require 'rack/utils'

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
        begin
          execute_and_build_result
        rescue StandardError => e
          handle_error_and_build_result(e)
        end
      end

      private

      attr_reader :options, :execution_logger, :logs

      def execute_and_build_result
        log_request
        response = do_request
        log_response(response)
        result = WebhookExecutionResult.new(WebhookRequestWithRedactedHeaders.new(http_request), response, logs.string)
        log_completion_message(result.success?)
        result
      end

      def handle_error_and_build_result e
        log_error(e)
        log_completion_message(false)
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

      def log_request
        redacted_request = WebhookRequestWithRedactedHeaders.new(http_request)
        logger.info "Making webhook #{uuid} request #{http_method.upcase} URI=#{uri} (headers and body in debug logs)"
        logger.debug "Webhook #{uuid} request headers=#{redacted_request.to_hash}"
        logger.debug "Webhook #{uuid} request body=#{redacted_request.body}"

        execution_logger.info "HTTP/1.1 #{http_method.upcase} #{url}"
        redacted_request.to_hash.each do | name, value |
          execution_logger.info "#{name}: #{value.join(", ")}"
        end
        execution_logger.info(body) if body
      end

      def log_response response
        log_response_to_application_logger(response)
        if options.fetch(:show_response)
          log_response_to_execution_logger(response)
        else
          execution_logger.info response_body_hidden_message
        end
      end

      def response_body_hidden_message
        PactBroker::Messages.message('messages.response_body_hidden')
      end

      def log_response_to_application_logger response
        logger.info "Received response for webhook #{uuid} status=#{response.code} (headers and body in debug logs)"
        logger.debug "Webhook #{uuid} response headers=#{response.to_hash} "
        logger.debug "Webhook #{uuid} response body=#{response.unsafe_body}"
      end

      def log_response_to_execution_logger response
        execution_logger.info "HTTP/#{response.http_version} #{response.code} #{response.message}"
        response.each_header do | name, value |
          execution_logger.info "#{name}: #{value}"
        end

        if response.body
          if response.unsafe_body?
            execution_logger.debug "Note that invalid UTF-8 byte sequences were removed from response body before saving the logs"
          end
          execution_logger.info response.body
        end
      end

      def log_completion_message success
        if options[:success_log_message] && success
          execution_logger.info(options[:success_log_message])
          logger.info(options[:success_log_message])
        end

        if options[:failure_log_message] && !success
          execution_logger.info(options[:failure_log_message])
          logger.info(options[:failure_log_message])
        end
      end

      def log_error e
        logger.info "Error executing webhook #{uuid} #{e.class.name} - #{e.message} #{e.backtrace.join("\n")}"

        if options[:show_response]
          execution_logger.error "Error executing webhook #{uuid} #{e.class.name} - #{e.message}"
        else
          execution_logger.error "Error executing webhook #{uuid}. #{response_body_hidden_message}"
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
