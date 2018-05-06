require_relative 'base_decorator'

module PactBroker
  module Api
    module Decorators
      class EmbeddedEnvironmentDecorator < BaseDecorator

        property :name

        link :self do | options |
          {
            title: 'Environment',
            name: represented.name,
            href: environment_url(options[:base_url], represented)
          }
        end
      end
    end
  end
end
