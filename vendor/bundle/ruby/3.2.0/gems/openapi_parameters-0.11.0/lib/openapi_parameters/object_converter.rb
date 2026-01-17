# frozen_string_literal: true

module OpenapiParameters
  # @visibility private
  ObjectConverter = Data.define(:schema) do
    def self.get_properties(schema) # rubocop:disable Metrics
      return nil if schema.nil? || schema.empty?

      direct_props = schema['properties']
      additional_props = schema['additionalProperties']

      composition_props = []

      %w[allOf oneOf anyOf].each do |keyword|
        next unless (array = schema[keyword])

        array.each do |sub_schema|
          if (props = sub_schema['properties'])
            composition_props << props
          end
        end
      end

      %w[then else].each do |keyword|
        next unless (sub_schema = schema[keyword])

        if (props = sub_schema['properties'])
          composition_props << props
        end
        if (add_props = sub_schema['additionalProperties']) && add_props.is_a?(Hash) && !add_props.empty?
          composition_props << add_props
        end
      end

      composition_props << additional_props if additional_props.is_a?(Hash) && !additional_props.empty?

      return direct_props if composition_props.empty? && direct_props
      return nil if direct_props.nil? && composition_props.empty?

      result = direct_props ? direct_props.dup : {}
      composition_props.each { |props| result.merge!(props) }
      result
    end

    def call(value)
      return value unless value.is_a?(Hash)

      properties = self.class.get_properties(schema)

      value.each_with_object({}) do |(key, val), hsh|
        hsh[key] = Converter.convert(val, properties&.fetch(key, nil))
      end
    end
  end
end
