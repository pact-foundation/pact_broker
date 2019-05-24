require_relative 'base_decorator'
require 'json'
require 'pact_broker/messages'

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
            rescue StandardError => e
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
            rescue StandardError => e
              represented.body
            end
          end
        end

        property :error, :extend => ErrorDecorator, if: lambda { |context| context[:options][:user_options][:show_response] }
        property :request, :extend => HTTPRequestDecorator
        property :response, :extend => HTTPResponseDecorator, if: lambda { |context| context[:options][:user_options][:show_response] }
        property :response_hidden_message, as: :message, exec_context: :decorator, if: lambda { |context| !context[:options][:user_options][:show_response] }

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

        def response_hidden_message
          PactBroker::Messages.message('messages.response_body_hidden')
        end
      end
    end
  end
end
