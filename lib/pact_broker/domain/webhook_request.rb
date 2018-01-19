require 'pact_broker/domain/webhook_request_header'
require 'pact_broker/domain/webhook_execution_result'
require 'pact_broker/logging'
require 'pact_broker/messages'
require 'net/http'
require 'pact_broker/webhooks/redact_logs'
require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/services'

module PactBroker

  module Domain

    class WebhookRequestError < StandardError

      def initialize message, response
        super message
        @response = response
      end

    end

    class WebhookRequest

      include PactBroker::Logging
      include PactBroker::Messages
      include PactBroker::Services

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

      def execute pact, options = {}
        logs = StringIO.new
        execution_logger = Logger.new(logs)
        begin
          execute_and_build_result(pact, options, logs, execution_logger)
        rescue StandardError => e
          handle_error_and_build_result(e, options, logs, execution_logger)
        end
      end

      private

      def execute_and_build_result pact, options, logs, execution_logger
        uri = build_uri(pact)
        req = build_request(uri, pact, execution_logger)
        response = do_request(uri, req)
        log_response(response, execution_logger)
        result = WebhookExecutionResult.new(response, logs.string)
        log_completion_message(options, execution_logger, result.success?)
        result
      end

      def handle_error_and_build_result e, options, logs, execution_logger
        logger.error "Error executing webhook #{uuid} #{e.class.name} - #{e.message} #{e.backtrace.join("\n")}"
        execution_logger.error "Error executing webhook #{uuid} #{e.class.name} - #{e.message}"
        log_completion_message(options, execution_logger, false)
        WebhookExecutionResult.new(nil, logs.string, e)
      end

      def build_request uri, pact, execution_logger
        req = http_request(uri)
        execution_logger.info "HTTP/1.1 #{method.upcase} #{url_with_credentials(pact)}"

        headers.each_pair do | name, value |
          execution_logger.info Webhooks::RedactLogs.call("#{name}: #{value}")
          req[name] = value
        end

        req.basic_auth(username, password) if username

        unless body.nil?
          if String === body
            req.body = gsub_body(pact, body)
          else
            req.body = gsub_body(pact, body.to_json)
          end
        end

        execution_logger.info req.body
        req
      end

      def do_request uri, req
        logger.info "Making webhook #{uuid} request #{to_s}"
        options = {}
        if uri.scheme == 'https'
          options[:use_ssl] = true
          options[:verify_mode] = OpenSSL::SSL::VERIFY_PEER
          options[:cert_store] = cert_store
        end
        Net::HTTP.start(uri.hostname, uri.port, options) do |http|
          http.request req
        end
      end

      def log_response response, execution_logger
        execution_logger.info(" ")
        logger.info "Received response for webhook #{uuid} status=#{response.code}"
        execution_logger.info "HTTP/#{response.http_version} #{response.code} #{response.message}"
        response.each_header do | header |
          execution_logger.info "#{header.split("-").collect(&:capitalize).join('-')}: #{response[header]}"
        end
        logger.debug "body=#{response.body}"
        safe_body = nil
        if response.body
          safe_body = response.body.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
          if response.body != safe_body
            execution_logger.debug "Note that invalid UTF-8 byte sequences were removed from response body before saving the logs"
          end
        end
        execution_logger.info safe_body
      end

      def log_completion_message options, execution_logger, success
        if options[:success_log_message] && success
          execution_logger.info(options[:success_log_message])
          logger.info(options[:success_log_message])
        end

        if options[:failure_log_message] && !success
          execution_logger.info(options[:failure_log_message])
          logger.info(options[:failure_log_message])
        end
      end

      def to_s
        "#{method.upcase} #{url}, username=#{username}, password=#{display_password}, headers=#{headers}, body=#{body}"
      end

      def http_request(uri)
        Net::HTTP.const_get(method.capitalize).new(uri)
      end

      def build_uri pact
        URI(gsub_url(pact, url))
      end

      def url_with_credentials pact
        u = build_uri(pact)
        u.userinfo = "#{username}:#{display_password}" if username
        u
      end

      def gsub_body pact, body
        base_url = PactBroker.configuration.base_url
        body.gsub('${pactbroker.pactUrl}', PactBroker::Api::PactBrokerUrls.pact_url(base_url, pact))
      end

      def gsub_url pact, url
        base_url = PactBroker.configuration.base_url
        pact_url = PactBroker::Api::PactBrokerUrls.pact_url(base_url, pact)
        escaped_pact_url = CGI::escape(pact_url)
        url.gsub('${pactbroker.pactUrl}', escaped_pact_url)
      end

      def cert_store
        certificate_service.cert_store
      end
    end
  end
end
