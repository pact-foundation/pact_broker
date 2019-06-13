require_relative 'base_decorator'
require_relative 'timestamps'

module PactBroker
  module Api
    module Decorators
      class SecretDecorator < BaseDecorator
        property :name
        property :description
        property :value, readable: false

        include Timestamps

        link :self do | context |
          {
            href: secret_url(represented, context[:base_url])
          }
        end
      end
    end
  end
end
