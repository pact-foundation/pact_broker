# frozen_string_literal: true

require_relative 'validators/response_headers'
require_relative 'validators/response_body'

module OpenapiFirst
  # Entry point for response validators
  class ResponseValidator
    VALIDATORS = [
      Validators::ResponseHeaders,
      Validators::ResponseBody
    ].freeze

    def initialize(content_schema:, headers:)
      @validators = []
      @validators << Validators::ResponseBody.new(content_schema) if content_schema
      @validators << Validators::ResponseHeaders.new(headers) if headers&.any?
    end

    def call(parsed_response)
      catch FAILURE do
        @validators.each { |v| v.call(parsed_response) }
        nil
      end
    end
  end
end
