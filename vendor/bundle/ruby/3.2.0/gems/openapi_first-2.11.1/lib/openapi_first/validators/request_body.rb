# frozen_string_literal: true

module OpenapiFirst
  module Validators
    class RequestBody
      def initialize(content_schema:, required_request_body:)
        @schema = content_schema
        @required = required_request_body
      end

      def call(parsed_request)
        body = parsed_request.body
        if body.nil?
          Failure.fail!(:invalid_body, message: 'Request body must not be empty') if @required
          return
        end

        validation = Schema::ValidationResult.new(
          @schema.validate(body, access_mode: 'write')
        )
        Failure.fail!(:invalid_body, errors: validation.errors) if validation.error?
      end
    end
  end
end
