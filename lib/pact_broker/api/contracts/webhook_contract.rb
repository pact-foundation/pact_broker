require 'pact_broker/api/contracts/base_contract'
require 'pact_broker/webhooks/check_host_whitelist'
require 'pact_broker/webhooks/render'
require 'pact_broker/pacticipants/service'

module PactBroker
  module Api
    module Contracts
      class WebhookContract < BaseContract

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

          optional(:consumer)
          optional(:provider)
          required(:request).filled
          optional(:events).maybe(min_size?: 1)
        end

        property :consumer do
          property :name

          validation do
            configure do
              config.messages_file = File.expand_path("../../../locale/en.yml", __FILE__)

              def pacticipant_exists?(name)
                !!PactBroker::Pacticipants::Service.find_pacticipant_by_name(name)
              end
            end

            required(:name).filled(:pacticipant_exists?)
          end

        end

        property :provider do
          property :name

          validation do
            configure do
              config.messages_file = File.expand_path("../../../locale/en.yml", __FILE__)

              def pacticipant_exists?(name)
                !!PactBroker::Pacticipants::Service.find_pacticipant_by_name(name)
              end
            end

            required(:name).filled(:pacticipant_exists?)
          end
        end

        property :request do
          property :url
          property :http_method

          validation do
            configure do
              config.messages_file = File.expand_path("../../../locale/en.yml", __FILE__)

              def self.messages
                super.merge(
                  en: {
                    errors: {
                      allowed_webhook_method?: http_method_error_message,
                      allowed_webhook_scheme?: scheme_error_message,
                      allowed_webhook_host?: host_error_message
                    }
                  }
                )
              end

              def self.http_method_error_message
                if PactBroker.configuration.webhook_http_method_whitelist.size == 1
                  "must be #{PactBroker.configuration.webhook_http_method_whitelist.first}. See /doc/webhooks#whitelist for more information."
                else
                  "must be one of #{PactBroker.configuration.webhook_http_method_whitelist.join(", ")}. See /doc/webhooks#whitelist for more information."
                end
              end

              def self.scheme_error_message
                "scheme must be #{PactBroker.configuration.webhook_scheme_whitelist.join(", ")}. See /doc/webhooks#whitelist for more information."
              end

              def self.host_error_message
                "host must be in the whitelist #{PactBroker.configuration.webhook_host_whitelist.join(",")}. See /doc/webhooks#whitelist for more information."
              end

              def valid_method?(http_method)
                Net::HTTP.const_defined?(http_method.capitalize)
              end

              def valid_url?(url)
                uri = parse_uri(url)
                uri.scheme && uri.host
              rescue URI::InvalidURIError, ArgumentError
                nil
              end

              def allowed_webhook_method?(http_method)
                PactBroker.configuration.webhook_http_method_whitelist.any? do | allowed_method |
                  http_method.downcase == allowed_method.downcase
                end
              end

              def allowed_webhook_scheme?(url)
                scheme = parse_uri(url).scheme
                PactBroker.configuration.webhook_scheme_whitelist.any? do | allowed_scheme |
                  scheme.downcase == allowed_scheme.downcase
                end
              end

              def allowed_webhook_host?(url)
                if host_whitelist.any?
                  PactBroker::Webhooks::CheckHostWhitelist.call(parse_uri(url).host, host_whitelist).any?
                else
                  true
                end
              end

              def non_templated_host?(url)
                parse_uri(url).host == parse_uri(url, 'differentplaceholder').host
              end

              def host_whitelist
                PactBroker.configuration.webhook_host_whitelist
              end

              def parse_uri(uri_string, placeholder = 'placeholder')
                URI(PactBroker::Webhooks::Render.render_with_placeholder(uri_string, placeholder))
              end
            end

            required(:http_method).filled(:valid_method?, :allowed_webhook_method?)
            required(:url).filled(:valid_url?, :allowed_webhook_scheme?, :allowed_webhook_host?, :non_templated_host?)
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
