require_relative 'base_decorator'
require 'json'

module PactBroker
  module Api
    module Decorators

      class WebhookExecutionResultDecorator < BaseDecorator

        class ErrorDecorator < BaseDecorator

          property :message
          property :backtrace

        end

        class HTTPResponseDecorator < BaseDecorator

          property :status, :getter => lambda { |_| code.to_i }
          property :headers, exec_context: :decorator
          property :body, exec_context: :decorator

          def headers
            headers_hash = represented.to_hash
            headers_hash.keys.each_with_object({}) do | name, new_headers_hash|
              new_headers_hash[name] = headers_hash[name].join(", ")
            end
          end

          def body
            begin
              ::JSON.parse(represented.body)
            rescue StandardError => e
              represented.body
            end
          end
        end

        property :message, exec_context: :decorator
        # property :error, :extend => ErrorDecorator
        # property :response, :extend => HTTPResponseDecorator

        def message
          "Webhook response has been redacted temporarily for security purposes. Please see the Pact Broker application logs for the response body."
        end

        link :webhook do | options |
          {
            href: webhook_url(options.fetch(:webhook).uuid, options.fetch(:base_url))
          }
        end

        link :'try-again' do | options |
          {
            title: 'Execute the webhook again',
            href: webhook_execution_url(options.fetch(:webhook), options.fetch(:base_url))
          }
        end
      end
    end
  end
end