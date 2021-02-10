require_relative 'base_decorator'
require_relative 'timestamps'

module PactBroker
  module Api
    module Decorators
      class EnvironmentDecorator < BaseDecorator
        property :uuid, writeable: false
        property :name
        property :label
        property :owners

        include Timestamps

        link :self do | options |
          {
            title: 'Environment',
            name: represented.name,
            href: options[:resource_url]
          }
        end
      end
    end
  end
end
