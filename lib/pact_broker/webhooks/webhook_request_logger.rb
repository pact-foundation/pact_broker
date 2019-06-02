require 'pact_broker/messages'
require 'pact_broker/logging'
require 'pact_broker/webhooks/http_request_with_redacted_headers'
require 'pact_broker/webhooks/http_response_with_utf_8_safe_body'

module PactBroker
  module Webhooks
    class WebhookRequestLogger
      include PactBroker::Logging

      attr_reader :execution_logger, :options

      def initialize(options)
        @log_stream = StringIO.new
        @execution_logger = Logger.new(log_stream)
        @options = options
      end

      def log(uuid, webhook_request, http_response, error)
        safe_response = http_response ? HttpResponseWithUtf8SafeBody.new(http_response) : nil
        log_request(webhook_request)
        log_response(uuid, safe_response) if safe_response
        log_error(uuid, error) if error
        log_completion_message(success?(safe_response))
        log_stream.string
      end

      private

      attr_reader :log_stream

      def log_request(webhook_request)
        http_request = HttpRequestWithRedactedHeaders.new(webhook_request.http_request)
        logger.info "Making webhook #{webhook_request.uuid} request #{http_request.method.upcase} URI=#{webhook_request.url} (headers and body in debug logs)"
        logger.debug "Webhook #{webhook_request.uuid} request headers=#{http_request.to_hash}"
        logger.debug "Webhook #{webhook_request.uuid} request body=#{http_request.body}"

        execution_logger.info "HTTP/1.1 #{webhook_request.http_method.upcase} #{webhook_request.url}"
        http_request.to_hash.each do | name, value |
          execution_logger.info "#{name}: #{value.join(", ")}"
        end
        execution_logger.info(webhook_request.body) if webhook_request.body
      end

      def log_response uuid, response
        log_response_to_application_logger(uuid, response)
        if options.fetch(:show_response)
          log_response_to_execution_logger(response)
        else
          execution_logger.info response_body_hidden_message
        end
      end

      def response_body_hidden_message
        PactBroker::Messages.message('messages.response_body_hidden')
      end

      def log_response_to_application_logger uuid, response
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

      def log_error uuid, e
        logger.info "Error executing webhook #{uuid} #{e.class.name} - #{e.message} #{e.backtrace.join("\n")}"

        if options[:show_response]
          execution_logger.error "Error executing webhook #{uuid} #{e.class.name} - #{e.message}"
        else
          execution_logger.error "Error executing webhook #{uuid}. #{response_body_hidden_message}"
        end
      end

      def success?(response)
        !response.nil? && response.code.to_i < 300
      end
    end
  end
end
