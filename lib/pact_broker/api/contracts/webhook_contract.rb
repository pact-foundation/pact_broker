require 'reform'
require 'reform/contract'

module PactBroker
  module Api
    module Contracts
      class WebhookContract < Reform::Contract

        property :request
        validates :request, presence: true

      end
    end
  end
end