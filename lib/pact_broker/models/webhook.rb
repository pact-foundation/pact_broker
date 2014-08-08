require 'pact_broker/models/webhook_request'
require 'pact_broker/messages'
require 'pact_broker/logging'

module PactBroker

  module Models

    class Webhook

      include Messages
      include Logging

      attr_accessor :uuid, :consumer, :provider, :request

      def initialize attributes = {}
        @uuid = attributes[:uuid]
        @request = attributes[:request]
        @consumer = attributes[:consumer]
        @provider = attributes[:provider]
      end

      def validate
        messages = []
        messages << message('errors.validation.attribute_missing', attribute: 'request') unless request
        messages.concat request.validate if request
        messages
      end

      def description
        "A webhook for the pact between #{consumer.name} and #{provider.name}"
      end

      #TODO retries
      def execute
        logger.info "Executing #{self}"
        begin
          request.execute
          logger.info "Successfully executed #{self}"
        rescue StandardError => e
          logger.error "Error executing webhook #{e.class.name} - #{e.message}"
          logger.error e.backtrace.join("\n")
          raise e
        end
      end

      def to_s
        "webhook for consumer=#{consumer.name} provider=#{provider.name} uuid=#{uuid} request=#{request}"
      end
    end

  end

end
