require_relative 'base_decorator'

module PactBroker
  module Api
    module Decorators
      class EmbeddedLabelDecorator < BaseDecorator

        property :name

        link :self do | options |
          {
            title: 'Label',
            name: represented.name,
            href: label_url(represented, options[:base_url])
          }
        end
      end
    end
  end
end
