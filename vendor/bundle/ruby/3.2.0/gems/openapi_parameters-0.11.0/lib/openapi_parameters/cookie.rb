# frozen_string_literal: true

module OpenapiParameters
  # Cookie parses OpenAPI cookie parameters from a cookie string.
  class Cookie
    # @param parameters [Array<Hash>] The OpenAPI parameter definitions.
    # @param convert [Boolean] Whether to convert the values to the correct type.
    def initialize(parameters, convert: true)
      @parameters = parameters.map { Parameter.new(_1) }
      @convert = convert
    end

    # @param cookie_string [String] The cookie string from the request. Example "foo=bar; baz=qux"
    def unpack(cookie_string)
      cookies = Rack::Utils.parse_cookies_header(cookie_string)
      parameters.each_with_object({}) do |parameter, result|
        next unless cookies.key?(parameter.name)

        result[parameter.name] = catch :skip do
          value = Unpacker.unpack_value(parameter, cookies[parameter.name])
          @convert ? parameter.convert(value) : value
        end
      end
    end

    private

    attr_reader :parameters
  end
end
