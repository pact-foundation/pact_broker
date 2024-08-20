# Builds the Hash that is passed into the Decorator as the `user_options`. It contains the request details, rack env, the (optional) title
# and anything else that is required by the decorator to render the resource (eg. the pacticipant that the versions belong to)

module PactBroker
  module Api
    module Decorators
      class DecoratorContextCreator

        # @param [PactBroker::BaseResource] the Pact Broker webmachine resource
        # @param [Hash] options any extra options that need to be passed through to the decorator.
        # @return [Hash] decorator_context

        # decorator_context [String] :base_url
        # The location where the Pact Broker is hosted.
        # eg. http://some.host:9292/pact_broker
        # Always present

        # decorator_context [String] :resource_url
        # The resource URL without any query string.
        # eg. http://some.host:9292/pact_broker/pacticipants/Foo/versions
        # Always present

        # decorator_context [String] :query_string
        # The query string.
        # "page=1&size=50"
        # May be empty

        # decorator_context [String] :request_url
        # The full request URL.
        # eg. http://some.host:9292/pact_broker/pacticipants/Foo/versions?page=1&size=50
        # Always present

        # decorator_context [Hash] :env
        # The rack env.
        # Always present

        # decorator_context [Hash] :resource_title
        # eg. "Pacticipant versions for Foo"
        # Optional
        # Used when a single decorator is being used for multiple resources and the title needs to be
        # set from the resource.

        def self.call(resource, options)
          env = resource.request.env
          decorator_context = {}
          decorator_context[:base_url] = resource.base_url
          decorator_context[:resource_url] = resource.resource_url
          decorator_context[:query_string] = query_string = (env["QUERY_STRING"] && !env["QUERY_STRING"].empty? ? env["QUERY_STRING"] : nil)
          decorator_context[:request_url] = query_string ? resource.resource_url + "?" + query_string : resource.resource_url
          decorator_context[:env] = env
          decorator_context[:resource_title] = options[:resource_title]
          decorator_context.merge!(options)
          decorator_context
        end
      end
    end
  end
end
