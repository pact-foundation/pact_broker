require "roar/decorator"
require "roar/json/hal"
require "pact_broker/api/pact_broker_urls"
require "pact_broker/api/decorators/decorator_context"
require "pact_broker/api/decorators/format_date_time"
require "pact_broker/string_refinements"
require "pact_broker/hash_refinements"

module PactBroker
  module Api
    module Decorators
      class BaseDecorator < Roar::Decorator
        include Roar::JSON::HAL
        include Roar::JSON::HAL::Links
        include PactBroker::Api::PactBrokerUrls
        include FormatDateTime
        using PactBroker::StringRefinements
        using PactBroker::HashRefinements

        # Call this method to automatically camelize property names without
        # having to define an :as each time.
        def self.camelize_property_names
          @camelize = true
        end

        # Overrides the default property method to add a camelised :as option
        # when camelize_property_names has been called for this decorator.
        # @override
        def self.property(name, options={}, &block)
          if options.delete(:camelize) || @camelize
            camelized_name = name.to_s.camelcase(false).to_sym
            super(name, { as: camelized_name }.merge(options), &block)
          else
            super
          end
        end

        # Returns the names of the model associations to eager load for use with this decorator
        # @return [Array<Symbol>]
        def self.eager_load_associations
          if is_collection_resource?
            collection_item_decorator_class.eager_load_associations
          else
            embedded_and_collection_attribute_names
          end
        end

        # Returns true if this class is a decorator for a collection
        # @return [true, false]
        def self.is_collection_resource?
          representable_attrs_without_links = representable_attrs.to_h.without("links", "page")
          representable_attrs_without_links.size == 1 &&
            representable_attrs_without_links.values.first[:collection] &&
            representable_attrs_without_links.values.first[:extend]
        end
        private_class_method :is_collection_resource?

        # Returns the names of the model attributes that are collections, embedded or nested items
        # @return [Array<Symbol>]
        def self.embedded_and_collection_attribute_names
          representable_attrs.values.select{ | attr| attr[:collection] || attr[:embedded] || attr[:nested] }.collect{ |attr| attr[:name].to_sym }
        end
        private_class_method :embedded_and_collection_attribute_names

        # @return [Class] The decorator class used to decorate the items in the collection
        def self.collection_item_decorator_class
          representable_attrs.to_h.without("links", "page").values.first[:extend].call
        end
        private_class_method :collection_item_decorator_class
      end
    end
  end
end
