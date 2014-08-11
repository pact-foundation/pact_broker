module PactBroker
  module Api
    module Decorators

      class DecoratorContext < Hash

        attr_reader :base_url, :resource_url, :resource_title

        def initialize base_url, resource_url, options
          @base_url = base_url
          @resource_url = resource_url
          @resource_title = options[:resource_title]
          merge!(options)
        end

      end

    end
  end
end