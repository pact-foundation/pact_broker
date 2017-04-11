require 'reform'
require 'reform/form'
require 'uri'

module PactBroker
  module Api
    module Contracts
      class VerificationContract < Reform::Form

        property :success
        property :provider_version, as: :providerVersion
        property :build_url, as: :buildUrl

        validation do
          configure do
            config.messages_file = File.expand_path("../../../locale/en.yml", __FILE__)

            def valid_url? url
              URI(url)
            rescue URI::InvalidURIError
              nil
            end
          end

          required(:success).filled(:bool?)
          optional(:build_url).maybe(:valid_url?)
        end
      end
    end
  end
end
