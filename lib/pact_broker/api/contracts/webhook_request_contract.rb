require "pact_broker/api/contracts/contract_support"
require "pact_broker/webhooks/render"
require "pact_broker/webhooks/check_host_whitelist"

module PactBroker
  module Api
    module Contracts
      class WebhookRequestContract < Dry::Validation::Contract
        include PactBroker::Api::Contracts::ValidationHelpers
        include PactBroker::Api::Contracts::DryValidationMethods

        json do
          required(:method).filled(:string)
          required(:url).filled(:string)
        end

        rule(:url) do
          if !valid_webhook_url?(value)
            key.failure(validation_message("invalid_url"))
          end
        end

        rule(:method) do
          if !valid_http_method?(value)
            key.failure(validation_message("invalid_http_method"))
          end
        end

        rule(:method) do
          if_still_valid(self) do
            if !allowed_webhook_method?(value)
              key.failure(http_method_error_message)
            end
          end
        end

        rule(:url) do
          if_still_valid(self) do
            if templated_host?(value)
              key.failure(validation_message("webhook_templated_host_not_allowed"))
            end
          end
        end

        rule(:url) do
          if_still_valid(self) do
            if !allowed_webhook_scheme?(value)
              key.failure(scheme_error_message)
            end
          end
        end

        rule(:url) do
          if_still_valid(self) do
            if !allowed_webhook_host?(value)
              key.failure(host_error_message)
            end
          end
        end

        def allowed_webhook_method?(http_method)
          PactBroker.configuration.webhook_http_method_whitelist.any? do | allowed_method |
            http_method.downcase == allowed_method.downcase
          end
        end

        def http_method_error_message
          if PactBroker.configuration.webhook_http_method_whitelist.size == 1
            "must be #{PactBroker.configuration.webhook_http_method_whitelist.first}. See /doc/webhooks#whitelist for more information."
          else
            "must be one of #{PactBroker.configuration.webhook_http_method_whitelist.join(", ")}. See /doc/webhooks#whitelist for more information."
          end
        end

        def allowed_webhook_scheme?(url)
          scheme = parse_uri(url).scheme
          PactBroker.configuration.webhook_scheme_whitelist.any? do | allowed_scheme |
            scheme.downcase == allowed_scheme.downcase
          end
        end

        def scheme_error_message
          "scheme must be #{PactBroker.configuration.webhook_scheme_whitelist.join(", ")}. See /doc/webhooks#whitelist for more information."
        end

        def parse_uri(uri_string, placeholder = "placeholder")
          URI(PactBroker::Webhooks::Render.render_with_placeholder(uri_string, placeholder))
        end

        def allowed_webhook_host?(url)
          if host_whitelist.any?
            PactBroker::Webhooks::CheckHostWhitelist.call(parse_uri(url).host, host_whitelist).any?
          else
            true
          end
        end

        def host_whitelist
          PactBroker.configuration.webhook_host_whitelist
        end

        def host_error_message
          "host must be in the whitelist #{PactBroker.configuration.webhook_host_whitelist.collect(&:inspect).join(", ")}. See /doc/webhooks#whitelist for more information."
        end

        def valid_webhook_url?(url)
          uri = parse_uri(url)
          uri.scheme && uri.host
        rescue URI::InvalidURIError, ArgumentError
          nil
        end

        def templated_host?(url)
          parse_uri(url).host != parse_uri(url, "differentplaceholder").host
        end

        def if_still_valid(context)
          if !context.rule_error?(context.path.keys)
            yield
          end
        end
      end
    end
  end
end
