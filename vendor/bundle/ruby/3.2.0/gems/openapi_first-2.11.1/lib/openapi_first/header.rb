# frozen_string_literal: true

module OpenapiFirst
  Header = Data.define(:name, :required?, :schema, :node) do
    def resolved_schema
      node['schema']&.resolved
    end
  end
end
