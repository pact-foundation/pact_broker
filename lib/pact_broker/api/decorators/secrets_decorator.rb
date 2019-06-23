require_relative 'secret_decorator'

module PactBroker
  module Api
    module Decorators
      class SecretsDecorator < BaseDecorator

        collection :entries, as: :secrets, embedded: true, :extend => SecretDecorator

        link :self do | context |
          {
            title: "Secrets",
            href: context[:resource_url]
          }
        end
      end
    end
  end
end
