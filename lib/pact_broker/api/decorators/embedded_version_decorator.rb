require_relative 'base_decorator'

module PactBroker
  module Api
    module Decorators
      class EmbeddedVersionDecorator < BaseDecorator
        camelize_property_names

        property :number
        if PactBroker.feature_enabled?(:branches)
          property :branch
          property :build_url
        end

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
