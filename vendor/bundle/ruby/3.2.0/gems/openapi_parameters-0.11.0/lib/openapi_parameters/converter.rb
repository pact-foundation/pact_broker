# frozen_string_literal: true

require_relative 'array_converter'
require_relative 'object_converter'

module OpenapiParameters
  # Tries to convert a request parameter value (string) to the type specified in the JSON Schema.
  # @visibility private
  module Converter
    class << self
      # @param value [String, Hash, Array] the value to convert
      # @param schema [Hash] the schema to use for conversion.
      def convert(value, schema) # rubocop:disable Metrics
        return if value.nil?
        return value if schema.nil?

        case type(schema)
        when 'integer'
          begin
            Integer(value, 10)
          rescue StandardError
            value
          end
        when 'number'
          begin
            Float(value)
          rescue StandardError
            value
          end
        when 'boolean'
          if value == 'true'
            true
          else
            value == 'false' ? false : value
          end
        when 'object'
          ObjectConverter.new(schema).call(value)
        when 'array'
          ArrayConverter.new(schema).call(value)
        else
          if schema['properties'] || schema['oneOf'] || schema['allOf'] || schema['anyOf']
            ObjectConverter.new(schema).call(value)
          else
            value
          end
        end
      end

      private

      def type(schema)
        schema && schema['type']
      end
    end
  end
end
