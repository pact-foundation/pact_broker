# frozen_string_literal: true

require 'rack'
require_relative 'converter'

module OpenapiParameters
  # Query parses query parameters from a http query strings.
  class Query
    # @param parameters [Array<Hash>] The OpenAPI query parameter definitions.
    # @param convert [Boolean] Whether to convert the values to the correct type.
    def initialize(parameters, convert: true, rack_array_compat: false)
      @parameters = parameters.map { Parameter.new(_1) }
      @convert = convert
      @remove_array_brackets = rack_array_compat
    end

    def unpack(query_string) # rubocop:disable Metrics/AbcSize
      parsed_query = parse_query(query_string)
      parameters.each_with_object({}) do |parameter, result|
        if parameter.deep_object?
          if parsed_query.key?(parameter.name)
            value = parsed_query[parameter.name]
          else
            value = parse_deep_object(parameter, parsed_query)
            next if value.empty?
          end
        else
          next unless parsed_query.key?(parameter.name)

          value = Unpacker.unpack_value(parameter, parsed_query[parameter.name])
        end
        key = if remove_array_brackets && parameter.bracket_array?
                parameter.name.delete_suffix('[]')
              else
                parameter.name
              end
        result[key] = @convert ? parameter.convert(value) : value
      end
    end

    def unknown_values(query_string)
      parsed_query = parse_query(query_string)
      known_parameter_names = parameters.to_set(&:name)

      unknown = parsed_query.each_with_object({}) do |(key, value), result|
        # Skip parameters that are defined in the schema
        next if known_parameter_names.include?(key)

        # Skip deep object parameters that might belong to defined parameters
        next if parameters.any? { |param| param.deep_object? && key.start_with?("#{param.name}[") }

        result[key] = value
      end
      return if unknown.empty?

      unknown
    end

    attr_reader :parameters
    private attr_reader :remove_array_brackets, :parameter_property_schemas

    private

    def parse_query(query_string)
      Rack::Utils.parse_query(query_string) do |s|
        Rack::Utils.unescape(s)
      rescue ArgumentError => e
        raise Rack::Utils::InvalidParameterError, e.message
      end
    end

    def build_properties_schema(parameter)
      schema = parameter.schema
      ObjectConverter.get_properties(schema) if schema
    end

    DEEP_PROP = '\[([\w-]+)\]$'
    private_constant :DEEP_PROP

    def parse_deep_object(parameter, parsed_query)
      name = parameter.name
      prop_regx = /^#{name}#{DEEP_PROP}/
      properties_schema = build_properties_schema(parameter)

      parsed_query.each.with_object({}) do |(key, value), result|
        next unless parsed_query.key?(key)

        prop_key = key.match(prop_regx)&.[](1)
        next if prop_key.nil?

        is_array = properties_schema&.dig(prop_key, 'type') == 'array'
        value = explode_value(value, parameter, is_array)
        result[prop_key] = value
      end
    end

    def explode_value(value, parameter, is_array)
      value = Array(value).map! { |v| Rack::Utils.unescape(v) }
      if is_array
        return value if parameter.explode?

        return [value.last]
      end
      value.last
    end
  end
end
