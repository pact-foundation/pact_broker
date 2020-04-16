module PactBroker
  module Api
    module Decorators
      class DecoratorContext < Hash

        attr_reader :base_url, :resource_url, :resource_title, :env

        def initialize base_url, resource_url, env, options = {}
          @base_url = self[:base_url] = base_url
          @resource_url = self[:resource_url]= resource_url
          @resource_title = self[:resource_title] = options[:resource_title]
          @env = self[:env] = env
          merge!(options)
        end

        def to_s
          "DecoratorContext #{super}"
        end
      end
    end
  end
end
