# frozen_string_literal: true

module OpenapiFirst
  class Router
    # @visibility private
    module FindContent
      def self.call(contents, content_type)
        return contents[nil] if content_type.nil? || content_type.empty?

        contents.fetch(content_type) do
          type = content_type.split(';')[0]
          contents[type] || contents["#{type.split('/')[0]}/*"] || contents['*/*'] || contents[nil]
        end
      end
    end
  end
end
