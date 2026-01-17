# frozen_string_literal: true

require 'forwardable'
require 'delegate'

module OpenapiFirst
  # A validated response. It can be valid or not.
  class ValidatedResponse < SimpleDelegator
    extend Forwardable

    def initialize(original_response, error:, parsed_values: nil, response_definition: nil)
      super(original_response)
      @error = error
      @parsed_values = parsed_values
      @response_definition = response_definition
    end

    # A Failure object if the response is invalid
    # @return [Failure, nil]
    attr_reader :error

    # The response definition if this response is defined in the API description
    # @return [Response, nil]
    attr_reader :response_definition

    # The parsed headers
    # @!method parsed_headers
    # @return [Hash<String,anything>]
    def_delegator :@parsed_values, :headers, :parsed_headers

    # The parsed body
    # @!method parsed_body
    # @return [Hash<String,anything>]
    def_delegator :@parsed_values, :body, :parsed_body

    # Checks if the response is valid.
    # @return [Boolean] true if the response is valid, false otherwise.
    def valid?
      error.nil?
    end

    # Returns true if the response is defined.
    def known? = response_definition != nil

    # Checks if the response is invalid.
    # @return [Boolean]
    def invalid?
      !valid?
    end
  end
end
