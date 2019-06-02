require 'pact_broker/messages'
module PactBroker
  module Webhooks
    class WebhookRequestLogger
      attr_reader :execution_logger, :logger, :uuid, :options

      def initialize(logger, execution_logger, uuid, options)
        @logger = logger
        @execution_logger = execution_logger
        @uuid = uuid
        @options = options
      end

      def log_all(webhook_request, http_request, response, error)
        log_request(http_request, webhook_request)
        log_response(response) if response
        log_error(error) if error
        log_completion_message(success?(response))
      end

      def log_request(redacted_request, webhook_request)
        logger.info "Making webhook #{webhook_request.uuid} request #{redacted_request.method.upcase} URI=#{webhook_request.url} (headers and body in debug logs)"
        logger.debug "Webhook #{webhook_request.uuid} request headers=#{redacted_request.to_hash}"
        logger.debug "Webhook #{webhook_request.uuid} request body=#{redacted_request.body}"

        execution_logger.info "HTTP/1.1 #{webhook_request.http_method.upcase} #{webhook_request.url}"
        redacted_request.to_hash.each do | name, value |
          execution_logger.info "#{name}: #{value.join(", ")}"
        end
        execution_logger.info(webhook_request.body) if webhook_request.body
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

      def success?(response)
        !response.nil? && response.code.to_i < 300
      end
    end
  end
end
