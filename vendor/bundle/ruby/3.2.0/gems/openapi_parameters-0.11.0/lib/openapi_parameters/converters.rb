# frozen_string_literal: true

module OpenapiParameters
  # Home for all converters
  module Converters
    @converters = {}

    class << self
      attr_reader :converters

      def register(type, converter)
        converters[type] = converter
      end

      def [](schema)
        type = schema && schema['type']
        converters.fetch(type) do
          return ArrayConverter.new(schema) if type == 'array'

          ->(value) { Converter.convert(value, schema) }
        end
      end
    end

    register('integer', lambda do |value|
      Integer(value, 10)
    rescue StandardError
      value
    end)

    register('number', lambda do |value|
      Float(value)
    rescue StandardError
      value
    end)

    register('boolean', lambda do |value|
      if value == 'true'
        true
      else
        value == 'false' ? false : value
      end
    end)
  end
end
