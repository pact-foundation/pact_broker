# frozen_string_literal: true

module OpenapiFirst
  # A failure object returned when validation or parsing of a request or response has failed.
  # This returned in ValidatedRequest#error and ValidatedResponse#error.
  class Failure
    TYPES = {
      not_found: [NotFoundError, 'Not found.'],
      method_not_allowed: [RequestInvalidError, 'Request method is not defined.'],
      unsupported_media_type: [RequestInvalidError, 'Request content type is not defined.'],
      invalid_body: [RequestInvalidError, 'Request body invalid:'],
      invalid_query: [RequestInvalidError, 'Query parameter is invalid:'],
      invalid_header: [RequestInvalidError, 'Request header is invalid:'],
      invalid_path: [RequestInvalidError, 'Path segment is invalid:'],
      invalid_cookie: [RequestInvalidError, 'Cookie value is invalid:'],
      response_not_found: [ResponseNotFoundError],
      invalid_response_body: [ResponseInvalidError, 'Response body is invalid:'],
      invalid_response_header: [ResponseInvalidError, 'Response header is invalid:']
    }.freeze
    private_constant :TYPES

    # @param type [Symbol] See Failure::TYPES.keys
    # @param errors [Array<OpenapiFirst::Schema::ValidationError>]
    def self.fail!(type, message: nil, errors: nil)
      throw FAILURE, new(
        type,
        message:,
        errors:
      )
    end

    # @param type [Symbol] See TYPES.keys
    # @param message [String] A generic error message
    # @param errors [Array<OpenapiFirst::Schema::ValidationError>]
    def initialize(type, message: nil, errors: nil)
      unless TYPES.key?(type)
        raise ArgumentError,
              "type must be one of #{TYPES.keys} but was #{type.inspect}"
      end

      @type = type
      @message = message
      @errors = errors
    end

    # @attr_reader [Symbol] type The type of the failure. See TYPES.keys.
    # Example: :invalid_body
    attr_reader :type

    # @attr_reader [Array<OpenapiFirst::Schema::ValidationError>] errors Schema validation errors
    attr_reader :errors

    # A generic error message
    def message
      @message ||= exception_message
    end

    def exception(context = nil)
      TYPES.fetch(type).first.new(exception_message, context)
    end

    def exception_message
      _, message_prefix = TYPES.fetch(type)

      [message_prefix, @message || generate_message].compact.join(' ')
    end

    # @deprecated Please use {#type} instead
    def error_type
      warn 'OpenapiFirst::Failure#error_type is deprecated. Use #type instead.'
      type
    end

    private

    def generate_message
      messages = errors&.take(3)&.map(&:message)
      messages << "... (#{errors.size} errors total)" if errors && errors.size > 3
      messages&.join('. ')
    end
  end
end
