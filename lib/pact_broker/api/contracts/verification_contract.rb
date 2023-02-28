require "pact_broker/api/contracts/base_contract"
require "uri"

module PactBroker
  module Api
    module Contracts
      class VerificationContract < BaseContract

        property :success
        property :provider_version, as: :providerApplicationVersion
        property :build_url, as: :buildUrl

        def self.not_blank? value
          value && value.to_s.strip.size > 0
        end

        def self.valid_url? url
          URI(url)
        rescue URI::InvalidURIError, ArgumentError
          nil
        end

        def self.valid_version_number?(value)
          return true if PactBroker.configuration.order_versions_by_date

          parsed_version_number = PactBroker.configuration.version_parser.call(value)
          !!parsed_version_number
        end

        validation do
          schema do
            configure do
              config.messages.load_paths << File.expand_path("../../../locale/en.yml", __FILE__)
            end

            required(:success).filled(:bool?)
            required(:provider_version).filled(:str?)
            optional(:build_url).maybe(:str?)
          end

          rule(:provider_version) do
            key.failure(:not_blank?) unless VerificationContract.not_blank?(value)
            key.failure(text: :valid_version_number?, value: value) unless VerificationContract.valid_version_number?(value)
          end
          rule(:build_url) do
            key.failure(:valid_url?) if key? && !VerificationContract.valid_url?(value)
          end
        end
      end
    end
  end
end
