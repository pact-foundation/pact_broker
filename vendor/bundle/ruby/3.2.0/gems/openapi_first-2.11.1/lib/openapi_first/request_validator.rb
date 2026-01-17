# frozen_string_literal: true

require_relative 'failure'
require_relative 'validators/request_parameters'
require_relative 'validators/request_body'

module OpenapiFirst
  # Validates a Request against a request definition.
  class RequestValidator
    def initialize(
      content_schema:,
      required_request_body:,
      path_schema:,
      query_schema:,
      header_schema:,
      cookie_schema:
    )
      @validators = []
      @validators << Validators::RequestBody.new(content_schema:, required_request_body:) if content_schema
      @validators.concat Validators::RequestParameters.for(
        path_schema:,
        query_schema:,
        header_schema:,
        cookie_schema:
      )
    end

    def call(parsed_request)
      @validators.each { |v| v.call(parsed_request) }
    end
  end
end
