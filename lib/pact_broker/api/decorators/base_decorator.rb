require "roar/decorator"
require "roar/json/hal"
require "pact_broker/api/pact_broker_urls"
require "pact_broker/api/decorators/decorator_context"
require "pact_broker/api/decorators/format_date_time"
require "pact_broker/string_refinements"

module PactBroker
  module Api
    module Decorators
      class BaseDecorator < Roar::Decorator
        include Roar::JSON::HAL
        include Roar::JSON::HAL::Links
        include PactBroker::Api::PactBrokerUrls
        include FormatDateTime
        using PactBroker::StringRefinements

        def self.camelize_property_names
          @camelize = true
        end

        def self.property(name, options={}, &block)
          if options.delete(:camelize) || @camelize
            camelized_name = name.to_s.camelcase(false).to_sym
            super(name, { as: camelized_name }.merge(options), &block)
          else
            super
          end
        end
      end
    end
  end
end
