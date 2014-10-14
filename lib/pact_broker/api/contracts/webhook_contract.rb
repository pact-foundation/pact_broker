require 'reform'
require 'reform/contract'
require 'pact_broker/api/contracts/request_validations'

module PactBroker
  module Api
    module Contracts

      class WebhookContract < Reform::Contract

        validates :request, presence: true

        property :request do

          include RequestValidations

          property :url, presence: true
          property :http_method, presence: true

          validate :method_is_valid
          validate :url_is_valid

        end

      end
    end
  end
end
