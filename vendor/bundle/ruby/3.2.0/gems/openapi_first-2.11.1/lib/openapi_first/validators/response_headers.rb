# frozen_string_literal: true

module OpenapiFirst
  module Validators
    class ResponseHeaders
      def initialize(headers)
        @headers = headers
      end

      attr_reader :headers

      def call(parsed_response)
        headers.each do |header|
          header_value = parsed_response.headers[header.name]
          next if header_value.nil? && !header.required?

          validation_errors = header.schema.validate(header_value)
          next unless validation_errors.any?

          Failure.fail!(:invalid_response_header,
                        errors: [error_for(data_pointer: "/#{header.name}", value: header_value,
                                           error: validation_errors.first)])
        end
      end

      private

      def error_for(data_pointer:, value:, error:)
        Schema::ValidationError.new(
          value: value,
          data_pointer:,
          schema_pointer: error['schema_pointer'],
          type: error['type'],
          details: error['details'],
          schema: error['schema']
        )
      end
    end
  end
end
