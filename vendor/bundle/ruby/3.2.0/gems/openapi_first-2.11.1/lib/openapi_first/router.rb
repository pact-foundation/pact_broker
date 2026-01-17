# frozen_string_literal: true

require_relative 'router/path_template'
require_relative 'router/find_content'
require_relative 'router/find_response'

module OpenapiFirst
  # Router can map requests / responses to their API definition
  class Router
    # Returned by {#match}
    RequestMatch = Data.define(:request_definition, :params, :error, :responses) do
      def match_response(status:, content_type:)
        FindResponse.call(responses, status, content_type, request_method: request_definition.request_method,
                                                           path: request_definition.path)
      end
    end

    # Returned by {#routes} to introspect all routes
    Route = Data.define(:path, :request_method, :requests, :responses)

    NOT_FOUND = RequestMatch.new(request_definition: nil, params: nil, responses: nil, error: Failure.new(:not_found))
    private_constant :NOT_FOUND

    def initialize
      @static = {}
      @dynamic = {} # TODO: use a trie or similar
    end

    # Returns an enumerator of all routes
    def routes
      @static.chain(@dynamic).lazy.flat_map do |path, request_methods|
        request_methods.filter_map do |request_method, content|
          next if request_method == :template

          Route.new(path:, request_method:, requests: content[:requests].each_value.lazy.uniq,
                    responses: content[:responses].each_value.lazy.flat_map(&:values))
        end
      end
    end

    # Add a request definition
    def add_request(request, request_method:, path:, content_type: nil, allow_empty_content: false)
      route = route_at(path, request_method)
      requests = route[:requests]
      requests[content_type] = request
      requests[nil] = request if allow_empty_content
    end

    # Add a response definition
    def add_response(response, request_method:, path:, status:, response_content_type: nil)
      (route_at(path, request_method)[:responses][status] ||= {})[response_content_type] = response
    end

    # Return all request objects that match the given path and request method
    def match(request_method, path, content_type: nil)
      path_item, params = find_path_item(path)
      unless path_item
        message = "Request path #{path} is not defined in API description."
        return NOT_FOUND.with(error: Failure.new(:not_found, message:))
      end

      contents = path_item.dig(request_method, :requests)
      return NOT_FOUND.with(error: Failure.new(:method_not_allowed)) unless contents

      request_definition = FindContent.call(contents, content_type)
      unless request_definition
        message = "#{content_type_err(content_type)} Content-Type should be #{contents.keys.join(' or ')}."
        return NOT_FOUND.with(error: Failure.new(:unsupported_media_type, message:))
      end

      responses = path_item.dig(request_method, :responses)
      RequestMatch.new(request_definition:, params:, error: nil, responses:)
    end

    private

    def route_at(path, request_method)
      request_method = request_method.upcase
      path_item = if PathTemplate.template?(path)
                    @dynamic[path] ||= { template: PathTemplate.new(path) }
                  else
                    @static[path] ||= {}
                  end
      path_item[request_method] ||= {
        requests: {},
        responses: {}
      }
    end

    def content_type_err(content_type)
      return 'Content-Type must not be empty.' if content_type.nil? || content_type.empty?

      "Content-Type #{content_type} is not defined."
    end

    def find_path_item(request_path)
      found = @static[request_path]
      return [found, {}] if found

      matches = @dynamic.filter_map do |_path, path_item|
        params = path_item[:template].match(request_path)
        next unless params

        [path_item, params]
      end
      return matches.first if matches.length == 1

      matches&.min_by { |match| match[1].values.sum(&:length) }
    end
  end
end
