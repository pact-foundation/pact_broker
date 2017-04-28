require 'reform'
require 'reform/form'
require 'uri'

module PactBroker
  module Api
    module Contracts
      class VerificationContract < Reform::Form

        property :success
        property :provider_version, as: :providerApplicationVersion
        property :build_url, as: :buildUrl

        validation do
          configure do
            config.messages_file = File.expand_path("../../../locale/en.yml", __FILE__)

            def not_blank? value
              value && value.to_s.strip.size > 0
            end

            def valid_url? url
              URI(url)
            rescue URI::InvalidURIError
              nil
            end

            def valid_version_number?(value)
              parsed_version_number = PactBroker.configuration.version_parser.call(value)
              !!parsed_version_number
            end
          end

          required(:success).filled(:bool?)
          required(:provider_version) { not_blank? & valid_version_number? }
          optional(:build_url).maybe(:valid_url?)
        end
      end
    end
  end
end
