require 'pact_broker/domain/webhook_request_header'
require 'pact_broker/domain/webhook_execution_result'
require 'pact_broker/logging'
require 'pact_broker/messages'
require 'net/http'

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

      def execute

        logs = StringIO.new
        execution_logger = Logger.new(logs)

        begin
          req = http_request
          execution_logger.info "HTTP/1.1 #{method.upcase} #{url_with_credentials}"

          headers.each_pair do | name, value |
            execution_logger.info "#{name}: #{value}"
            req[name] = value
          end

          req.basic_auth(username, password) if username

          unless body.nil?
            if String === body
              req.body = body
            else
              req.body = body.to_json
            end
          end

          execution_logger.info req.body

          logger.info "Making webhook #{uuid} request #{to_s}"

          response = Net::HTTP.start(uri.hostname, uri.port,
            :use_ssl => uri.scheme == 'https') do |http|
            http.request req
          end

          execution_logger.info(" ")
          logger.info "Received response for webhook #{uuid} status=#{response.code}"
          execution_logger.info "HTTP/#{response.http_version} #{response.code} #{response.message}"
          response.each_header do | header |
            execution_logger.info "#{header.split("-").collect(&:capitalize).join('-')}: #{response[header]}"
          end
          logger.debug "body=#{response.body}"
          execution_logger.info response.body
          WebhookExecutionResult.new(response, logs.string)

        rescue StandardError => e
          logger.error "Error executing webhook #{uuid} #{e.class.name} - #{e.message}"
          execution_logger.error "Error executing webhook #{uuid} #{e.class.name} - #{e.message}"
          logger.error e.backtrace.join("\n")
          execution_logger.error e.backtrace.join("\n")
          WebhookExecutionResult.new(nil, logs.string, e)
        end

      end

      private

      def to_s
        "#{method.upcase} #{url}, username=#{username}, password=#{display_password}, headers=#{headers}, body=#{body}"
      end

      def http_request
        Net::HTTP.const_get(method.capitalize).new(url)
      end

      def uri
        URI(url)
      end

      def url_with_credentials
        u = URI(url)
        u.userinfo = "#{username}:#{display_password}" if username
        u
      end
    end

  end

end
