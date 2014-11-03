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

      attr_accessor :method, :url, :headers, :body, :username, :password

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
      end

      def description
        "#{method.upcase} #{URI(url).host}"
      end

      def display_password
        password.nil? ? nil : "**********"
      end

      def execute

        begin
          #TODO make it work with https
          req = http_request

          headers.each_pair do | name, value |
            req[name] = value
          end

          req.basic_auth(username, password) if username

          req.body = body

          logger.info "Making webhook request #{to_s}"
          response = Net::HTTP.start(uri.hostname, uri.port) do |http|
            http.request req
          end

          logger.info "Received response status=#{response.code} body=#{response.body}"
          WebhookExecutionResult.new(response)

        rescue StandardError => e
          logger.error "Error executing webhook #{e.class.name} - #{e.message}"
          logger.error e.backtrace.join("\n")
          WebhookExecutionResult.new(nil, e)
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
    end

  end

end
