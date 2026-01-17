# frozen_string_literal: true

require_relative 'request_parser'
require_relative 'request_validator'
require_relative 'validated_request'

module OpenapiFirst
  # Represents one request definition of an OpenAPI description.
  # Note that this is not the same as an OpenAPI 3.x Operation.
  # An 3.x Operation object can accept multiple requests, because it can handle multiple content-types.
  # This class represents one of those requests.
  class Request
    # rubocop:disable Metrics/MethodLength
    def initialize(path:, request_method:, operation_object:,
                   parameters:, content_type:, content_schema:, required_body:, key:)
      @path = path
      @request_method = request_method
      @content_type = content_type
      @content_schema = content_schema
      @operation = operation_object
      @allow_empty_content = content_type.nil? || required_body == false
      @key = key
      @request_parser = RequestParser.new(
        query_parameters: parameters.query,
        path_parameters: parameters.path,
        header_parameters: parameters.header,
        cookie_parameters: parameters.cookie,
        content_type:
      )
      @validator = RequestValidator.new(
        content_schema:,
        required_request_body: required_body == true,
        path_schema: parameters.path_schema,
        query_schema: parameters.query_schema,
        header_schema: parameters.header_schema,
        cookie_schema: parameters.cookie_schema
      )
    end
    # rubocop:enable Metrics/MethodLength

    attr_reader :content_type, :content_schema, :operation, :request_method, :path, :key

    def allow_empty_content?
      @allow_empty_content
    end

    def validate(request, route_params:)
      parsed_request = nil
      error = catch FAILURE do
        parsed_request = @request_parser.parse(request, route_params:)
        @validator.call(parsed_request)
        nil
      end
      ValidatedRequest.new(request, parsed_request:, error:, request_definition: self)
    end

    def operation_id
      @operation['operationId']
    end
  end
end
