# frozen_string_literal: true

require 'rack'

module OpenapiParameters
  # Parses OpenAPI path parameters from a route params Hash that is usually provided by your Rack webframework
  class Path
    # @param parameters [Array<Hash>] The OpenAPI path parameters.
    # @param convert [Boolean] Whether to convert the values to the correct type.
    def initialize(parameters, convert: true)
      @parameters = parameters.map { Parameter.new(_1) }
      @convert = convert
    end

    attr_reader :parameters

    # @param path_params [Hash] The path parameters from the Rack request. The keys are strings.
    def unpack(path_params)
      parameters.each_with_object({}) do |parameter, result|
        next unless path_params.key?(parameter.name)

        result[parameter.name] = catch :skip do
          value = Unpacker.unpack_value(parameter, path_params[parameter.name])
          @convert ? parameter.convert(value) : value
        end
      end
    end
  end
end
