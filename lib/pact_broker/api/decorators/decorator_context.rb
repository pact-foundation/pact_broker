module PactBroker
  module Api
    module Decorators
      class DecoratorContext < Hash
        attr_reader :base_url, :resource_url, :resource_title, :env, :path_params, :query_string

        # @param base_url [String]
        # @param resource_url [String]
        # @param env [Hash] The rack env
        # @param path_params [Hash] The params parsed from the resource path in Webmachine
        # @param resource_title [String] Optional title for the resource to be used in the decorator
        # @param other_options [Hash] Any other custom parameters to pass through to the decorator
        def initialize base_url, resource_url, env, path_params:, resource_title: nil,  **custom_options: {}
          @base_url = self[:base_url] = base_url
          @resource_url = self[:resource_url] = resource_url
          @env = self[:env] = env
          @query_string = self[:query_string] = (env["QUERY_STRING"] && !env["QUERY_STRING"].empty? ? env["QUERY_STRING"] : nil)
          @resource_title = self[:resource_title] = resource_title
          @path_params = self[:path_params] = path_params
          merge!(custom_options)
        end

        def to_s
          "DecoratorContext #{super}"
        end
      end
    end
  end
end
