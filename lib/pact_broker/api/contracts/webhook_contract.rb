require "pact_broker/api/contracts/base_contract"
require "pact_broker/webhooks/check_host_whitelist"
require "pact_broker/webhooks/render"
require "pact_broker/pacticipants/service"
require "pact_broker/webhooks/webhook_event"
require "dry/validation"

module PactBroker
  module Api
    module Contracts
      class WebhookContract < BaseContract

        def self.host_whitelist
          PactBroker.configuration.webhook_host_whitelist
        end

        def self.parse_uri(uri_string, placeholder = "placeholder")
          URI(PactBroker::Webhooks::Render.render_with_placeholder(uri_string, placeholder))
        end

        def self.valid_method?(http_method)
          Net::HTTP.const_defined?(http_method.capitalize)
        rescue StandardError
          false
        end

        def self.allowed_webhook_method?(http_method)
          PactBroker.configuration.webhook_http_method_whitelist.any? do | allowed_method |
            http_method.downcase == allowed_method.downcase
          end
        end

        def self.valid_url?(url)
          uri = WebhookContract.parse_uri(url)
          uri.scheme && uri.host
        rescue URI::InvalidURIError, ArgumentError
          nil
        end

        def self.allowed_webhook_scheme?(url)
          scheme = WebhookContract.parse_uri(url).scheme
          PactBroker.configuration.webhook_scheme_whitelist.any? do | allowed_scheme |
            scheme && scheme.downcase == allowed_scheme.downcase
          end
        rescue URI::InvalidURIError, ArgumentError
          nil
        end

        def self.allowed_webhook_host?(url)
          if valid_url?(url) && host_whitelist.any?
            PactBroker::Webhooks::CheckHostWhitelist.call(WebhookContract.parse_uri(url).host,
                                                          WebhookContract.host_whitelist).any?
          else
            true
          end
        end

        def self.non_templated_host?(url)
          valid_url?(url) && parse_uri(url).host == WebhookContract.parse_uri(url, "differentplaceholder").host
        end

        ::Dry::Validation.register_macro(:valid_method?) do
          key.failure(:valid_method?) unless WebhookContract.valid_method?(value)
        end

        ::Dry::Validation.register_macro(:allowed_webhook_method?) do
          key.failure(:allowed_webhook_method?) unless WebhookContract.allowed_webhook_method?(value)
        end

        ::Dry::Validation.register_macro(:valid_url?) do
          key.failure(:valid_url?) unless WebhookContract.valid_url?(value)
        end

        ::Dry::Validation.register_macro(:allowed_webhook_scheme?) do
          key.failure(:allowed_webhook_scheme?) unless key? && WebhookContract.allowed_webhook_scheme?(value)
        end

        ::Dry::Validation.register_macro(:allowed_webhook_host?) do
          key.failure(:allowed_webhook_host?) unless WebhookContract.allowed_webhook_host?(value)
        end

        ::Dry::Validation.register_macro(:non_templated_host?) do
          key.failure(:non_templated_host?) unless WebhookContract.non_templated_host?(value)
        end

        ::Dry::Validation.register_macro(:pacticipant_exists?) do
          key.failure(:pacticipant_exists?) unless !!PactBroker::Pacticipants::Service.find_pacticipant_by_name(value)
        end

        def validate(*)
          result = super
          # I just cannot seem to get the validation to stop on the first error.
          # If one rule fails, they all come back failed, and it's driving me nuts.
          # Why on earth would I want that behaviour?
          # I cannot believe I have to do this shit.
          @first_errors = errors
          @first_errors.messages.keys.each do | key |
            @first_errors.messages[key] = @first_errors.messages[key][0...1]
          end

          # rubocop: disable Lint/NestedMethodDefinition
          def self.errors; @first_errors end
          # rubocop: enable Lint/NestedMethodDefinition

          result
        end

        validation do
          schema do
            configure do
              config.messages.load_paths << File.expand_path("../../../locale/en.yml", __FILE__)
            end

            optional(:consumer)
            optional(:provider)
            required(:request).filled
            optional(:events).maybe(min_size?: 1)
          end
        end

        property :consumer do
          property :name
          property :label

          validation do
            schema do
              configure do
                config.messages.load_paths << File.expand_path("../../../locale/en.yml", __FILE__)
              end

              optional(:name)
                .maybe(:str?)
                # .when(:none?) { value(:label).filled? }

              optional(:label)
                .maybe(:str?)
                # .when(:none?) { value(:name).filled? }
            end

            rule(:name, :label) do
              # Original:
              # (name.filled? & label.filled?) > label.none?
              # assuming this means you can provider neither, both or just the name
              key.failure(:webhook_consumer_name_and_label) if key?(:label) && !key?(:name)
            end
            rule(:name).validate(:pacticipant_exists?)
          end
        end

        property :provider do
          property :name
          property :label

          validation do
            schema do
              configure do
                config.messages.load_paths << File.expand_path("../../../locale/en.yml", __FILE__)
              end

              optional(:name)
                .maybe(:str?)
                # .when(:none?) { value(:label).filled? }

              optional(:label)
                .maybe(:str?)
                # .when(:none?) { value(:name).filled? }
            end

            rule(:name, :label) do
              # Original:
              # (name.filled? & label.filled?) > label.none?
              # assuming this means you can provider neither, both or just the name
              key.failure(:webhook_provider_name_and_label) if key?(:label) && !key?(:name)
            end
            rule(:name).validate(:pacticipant_exists?)
          end
        end

        property :request do
          property :url
          property :http_method

          validation do
            schema do
              configure do
                config.messages.load_paths << File.expand_path("../../../locale/en.yml", __FILE__)

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
              end

              required(:http_method).filled(:str?)
              required(:url).filled(:str?)
            end

            rule(:http_method).validate(:valid_method?, :allowed_webhook_method?)
            rule(:url).validate(:valid_url?, :allowed_webhook_scheme?, :allowed_webhook_host?, :non_templated_host?)
          end
        end

        collection :events do
          property :name

          validation do
            schema do
              required(:name).filled(included_in?: PactBroker::Webhooks::WebhookEvent::EVENT_NAMES)
            end
          end
        end
      end
    end
  end
end
