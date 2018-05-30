require 'reform'
require 'reform/form'
require 'pact_broker/webhooks/service'

module PactBroker
  module Api
    module Contracts
      class WebhookContract < Reform::Form

        def validate(*)
          result = super
          # I just cannot seem to get the validation to stop on the first error.
          # If one rule fails, they all come back failed, and it's driving me nuts.
          # Why on earth would I want that behaviour?
          new_errors = Reform::Contract::Errors.new
          errors.messages.each do | key, value |
            new_errors.add(key, value.first)
          end
          @errors = new_errors
          result
        end

        validation do
          configure do
            config.messages_file = File.expand_path("../../../locale/en.yml", __FILE__)
          end

          required(:request).filled
          optional(:events).maybe(min_size?: 1)
        end

        property :request do
          property :url
          property :http_method

          validation do
            configure do
              config.messages_file = File.expand_path("../../../locale/en.yml", __FILE__)

              def valid_method?(value)
                Net::HTTP.const_defined?(value.capitalize)
              end

              def valid_url?(value)
                uri = URI(value)
                uri.scheme && uri.host
              rescue URI::InvalidURIError
                false
              end

              def webhook_url_allowed?(value)
                !PactBroker::Webhooks::Service.url_blacklisted?(value)
              end
            end

            required(:http_method).filled(:valid_method?)
            required(:url).filled(:valid_url?, :webhook_url_allowed?)
          end
        end

        collection :events do
          property :name

          validation do
            required(:name).filled
          end
        end
      end
    end
  end
end
