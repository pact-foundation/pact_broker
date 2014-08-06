require 'pact_broker/models/webhook_request_header'
require 'pact_broker/logging'
require 'pact_broker/messages'

module PactBroker

  module Models

    class WebhookRequestError < StandardError; end

    class WebhookRequest

      include PactBroker::Logging
      include PactBroker::Messages

      attr_accessor :method, :url, :headers, :body

      def initialize attributes = {}
        @method = attributes[:method]
        @url = attributes[:url]
        @headers = attributes[:headers] || {}
        @body = attributes[:body]
      end

      def execute
        #TODO make it work with https
        #TODO validation of method
        req = http_request

        headers.each do | header |
          req[header.name] = header.value
        end
        req.body = body

        logger.info "Making webhook request #{to_s}"
        response = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request req
        end

        logger.info "Received response status=#{response.code} body=#{response.body}"

        if Net::HTTPOK === response
          true
        else
          raise WebhookRequestError.new("status=#{response.code} body=#{response.body}")
        end

      end

      def validate
        messages = []
        messages << message('errors.validation.attribute_missing', attribute: 'method') unless method
        messages << message('errors.validation.attribute_missing', attribute: 'url') unless url
        messages << message('errors.validation.invalid_http_method', method: method) unless method && method_valid?
        messages << message('errors.validation.invalid_url', url: url) unless url && url_valid?
        messages
      end

      private

      def to_s
        "#{method.upcase} #{url}, headers=#{headers}, body=#{body}"
      end

      def http_request
        Net::HTTP.const_get(method.capitalize).new(url)
      end

      def method_valid?
        Net::HTTP.const_defined?(method.capitalize)
      end

      def url_valid?
        uri.scheme && uri.host
      end

      def uri
        URI(url)
      end
    end

  end

end
