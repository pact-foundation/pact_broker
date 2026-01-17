# frozen_string_literal: true

module OpenapiParameters
  # @visibility private
  ArrayConverter = Data.define(:schema) do
    def call(value)
      return [] if value.nil? || value.empty?

      convert_array(value)
    end

    private

    def convert_array(array)
      return array unless array.is_a?(Array)

      item_schema = schema['items']
      prefix_schemas = schema['prefixItems']
      return convert_array_with_prefixes(array, prefix_schemas, item_schema) if prefix_schemas

      array.map { |item| Converter.convert(item, item_schema) }
    end

    def convert_array_with_prefixes(array, prefix_schemas, item_schema)
      prefixes =
        array
        .slice(0, prefix_schemas.size)
        .each_with_index
        .map { |item, index| Converter.convert(item, prefix_schemas[index]) }
      array =
        array[prefix_schemas.size..].map! do |item|
          Converter.convert(item, item_schema)
        end
      prefixes + array
    end
  end
end
