# frozen_string_literal: true

module OpenapiParameters
  # Unpacks a parameter value from a string as defined in the OpenAPI specification.
  # @visibility private
  module Unpacker
    class << self
      def unpack_value(parameter, value)
        return value if value.nil?
        return unpack_array(parameter, value) if parameter.array?
        return unpack_object(parameter, value) if parameter.object?

        value
      end

      def unpack_array(parameter, value)
        return value if value.is_a?(Array)
        return value if value.empty?
        return unpack_matrix(parameter, value) if parameter.style == 'matrix'

        value = value[1..] if PREFIXED.key?(parameter.style)
        value.split(ARRAY_DELIMITER[parameter.style])
      end

      def unpack_matrix(parameter, value)
        result = Rack::Utils.parse_query(value, ';')[parameter.name]
        return result if parameter.explode?

        result.split(',')
      end

      OBJECT_EXPLODE_SPLITTER = Regexp.union(',', '=').freeze
      private_constant :OBJECT_EXPLODE_SPLITTER

      def unpack_object(parameter, value)
        return unpack_object_path(parameter, value) if parameter.location == 'path'

        entries =
          if parameter.explode?
            value.split(OBJECT_EXPLODE_SPLITTER)
          else
            value.split(ARRAY_DELIMITER[parameter.style])
          end
        throw :skip, value if entries.length.odd?

        Hash[*entries]
      end

      def unpack_object_path(parameter, value)
        return Rack::Utils.parse_query(value, ',') if parameter.explode?

        array = unpack_array(parameter, value)
        throw :skip, value if array.length.odd?

        Hash[*array]
      end

      PREFIXED = {
        'label' => '.',
        'matrix' => ';'
      }.freeze

      ARRAY_DELIMITER = {
        'label' => '.',
        'simple' => ',',
        'form' => ',',
        'pipeDelimited' => '|',
        'spaceDelimited' => ' '
      }.freeze
      private_constant :ARRAY_DELIMITER
    end
  end
end
