module PactBroker
  module Api
    module Decorators
      class DecoratorContext < Hash
        attr_reader :base_url, :resource_url, :resource_title, :env, :query_string, :request_url

        def initialize base_url, resource_url, env, options = {}
          @base_url = self[:base_url] = base_url
          @resource_url = self[:resource_url] = resource_url
          @resource_title = self[:resource_title] = options[:resource_title]
          @env = self[:env] = env
          @query_string = self[:query_string] = (env["QUERY_STRING"] && !env["QUERY_STRING"].empty? ? env["QUERY_STRING"] : nil)
          @request_url = self[:request_url] = query_string ? resource_url + "?" + query_string : resource_url
          merge!(options)
        end

        def to_s
          "DecoratorContext #{super}"
        end
      end
    end
  end
end
