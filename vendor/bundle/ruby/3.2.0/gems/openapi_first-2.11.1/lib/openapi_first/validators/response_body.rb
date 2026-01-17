# frozen_string_literal: true

require_relative '../schema/validation_result'

module OpenapiFirst
  module Validators
    class ResponseBody
      def initialize(schema)
        @schema = schema
      end

      attr_reader :schema

      def call(response)
        begin
          parsed_body = response.body
        rescue ParseError => e
          Failure.fail!(:invalid_response_body, message: e.message)
        end
        validation = Schema::ValidationResult.new(
          schema.validate(parsed_body, access_mode: 'read')
        )
        Failure.fail!(:invalid_response_body, errors: validation.errors) if validation.error?
      end
    end
  end
end
