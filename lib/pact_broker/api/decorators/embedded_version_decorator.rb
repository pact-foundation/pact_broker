require_relative 'base_decorator'

module PactBroker
  module Api
    module Decorators
      class EmbeddedVersionDecorator < BaseDecorator
        camelize_property_names

        property :number
        property :branch
        property :build_url

        link :self do | options |
          {
            title: 'Version',
            name: represented.number,
            href: version_url(options.fetch(:base_url), represented)
          }
        end
      end
    end
  end
end
