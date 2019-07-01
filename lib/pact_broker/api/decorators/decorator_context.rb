module PactBroker
  module Api
    module Decorators

      class DecoratorContext < Hash

        attr_reader :base_url, :resource_url, :resource_title

        def initialize base_url, resource_url, options = {}
          @base_url = base_url
          self[:base_url] = base_url
          @resource_url = resource_url
          self[:resource_url] = resource_url
          if options[:resource_title]
            @resource_title = options[:resource_title]
            self[:resource_title] = resource_title
          end
          merge!(options)
        end

        def to_s
          "DecoratorContext #{super}"
        end
      end
    end
  end
end
