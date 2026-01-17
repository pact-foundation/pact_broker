# frozen_string_literal: true

module OpenapiFirst
  module Schema
    # One of multiple validation errors. Returned by Schema::ValidationResult#errors.
    ValidationError = Data.define(:value, :data_pointer, :schema_pointer, :type, :details, :schema) do
      # This returns an error message for this specific error.
      # This it copied from json_schemer here to be easier to customize when passing custom data_pointers.
      def message
        location = data_pointer.empty? ? 'root' : "`#{data_pointer}`"

        case type
        when 'required'
          keys = details.fetch('missing_keys', []).join(', ')
          "object at #{location} is missing required properties: #{keys}"
        when 'dependentRequired'
          keys = details.fetch('missing_keys').join(', ')
          "object at #{location} is missing required properties: #{keys}"
        when 'string', 'boolean', 'number'
          "value at #{location} is not a #{type}"
        when 'array', 'object', 'integer'
          "value at #{location} is not an #{type}"
        when 'null'
          "value at #{location} is not #{type}"
        when 'pattern'
          "string at #{location} does not match pattern: #{schema.fetch('pattern')}"
        when 'format'
          "value at #{location} does not match format: #{schema.fetch('format')}"
        when 'const'
          "value at #{location} is not: #{schema.fetch('const').inspect}"
        when 'enum'
          "value at #{location} is not one of: #{schema.fetch('enum')}"
        when 'minimum'
          "number at #{location} is less than: #{schema['minimum']}"
        when 'maximum'
          "number at #{location} is greater than: #{schema['maximum']}"
        when 'readOnly'
          "value at #{location} is `readOnly`"
        else
          "value at #{location} is invalid (#{type.inspect})"
        end
      end

      # @deprecated Please use {#message} instead
      def error
        warn 'OpenapiFirst::Schema::ValidationError#error is deprecated. Use #message instead.'
        message
      end

      # @deprecated Please use {#data_pointer} instead
      def instance_location
        warn 'OpenapiFirst::Schema::ValidationError#instance_location is deprecated. Use #data_pointer instead.'
        data_pointer
      end

      # @deprecated Please use {#schema_pointer} instead
      def schema_location
        warn 'OpenapiFirst::Schema::ValidationError#schema_location is deprecated. Use #schema_pointer instead.'
        schema_pointer
      end
    end
  end
end
