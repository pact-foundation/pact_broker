require_relative "base_decorator"
require "json"
require "pact_broker/messages"

module PactBroker
  module Api
    module Decorators
      class WebhookExecutionResultDecorator < BaseDecorator
        class ErrorDecorator < BaseDecorator
          property :message
        end

        class HTTPRequestDecorator < BaseDecorator
          property :headers, exec_context: :decorator
          property :body, exec_context: :decorator
          property :url, exec_context: :decorator

          def headers
            headers_hash = represented.to_hash
            headers_hash.keys.each_with_object({}) do | name, new_headers_hash|
              new_headers_hash[name] = headers_hash[name].join(", ")
            end
          end

          def body
            begin
              ::JSON.parse(represented.body)
            rescue StandardError => _ex
              represented.body
            end
          end

          def url
            (represented.uri || represented.path).to_s
          end
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
            rescue StandardError => _ex
              represented.body
            end
          end
        end

        property :error, :extend => ErrorDecorator, if: lambda { |options:, **| options.dig(:user_options, :show_response) }
        property :request, :extend => HTTPRequestDecorator
        property :response, :extend => HTTPResponseDecorator, if: lambda { |options:, **| options.dig(:user_options, :show_response) }
        property :message,
          if: lambda { |options:, **| !options.dig(:user_options, :show_response) },
          getter: lambda { |options:, **| PactBroker::Messages.message("messages.response_body_hidden", base_url: options.dig(:user_options, :base_url))  }
        property :logs
        property :success?, as: :success

        #TODO rename to pb:webhook in next major version
        link :webhook do | options |
          if options.fetch(:webhook).uuid
            {
              href: webhook_url(options.fetch(:webhook).uuid, options.fetch(:base_url))
            }
          end
        end

        #TODO rename to pb:try-again in next major version
        link :'try-again' do | options |
          {
            title: "Execute the webhook again",
            href: options.fetch(:resource_url)
          }
        end
      end
    end
  end
end
