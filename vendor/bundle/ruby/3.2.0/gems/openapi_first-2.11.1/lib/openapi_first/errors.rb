# frozen_string_literal: true

module OpenapiFirst
  # Base class for all errors
  class Error < StandardError; end

  # Raised if YAML/JSON file was not found
  class FileNotFoundError < Error; end

  # Raised if response body could not be parsed
  class ParseError < Error; end

  # Raised during request validation if request was invalid
  class RequestInvalidError < Error
    def initialize(message, validated_request)
      super(message)
      @request = validated_request
    end

    # @return [ValidatedRequest] The validated request
    attr_reader :request
  end

  # Raised during request validation if request was not defined in the API description
  class NotFoundError < RequestInvalidError; end

  # Raised during response validation if request was invalid
  class ResponseInvalidError < Error
    def initialize(message, validated_response)
      super(message)
      @response = validated_response
    end

    # @return [ValidatedResponse] The validated response
    attr_reader :response
  end

  # Raised during request validation if response was not defined in the API description
  class ResponseNotFoundError < ResponseInvalidError; end
end
