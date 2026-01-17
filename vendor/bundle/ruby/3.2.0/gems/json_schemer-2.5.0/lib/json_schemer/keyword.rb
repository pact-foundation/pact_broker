# frozen_string_literal: true
module JSONSchemer
  class Keyword
    include Output

    attr_reader :value, :parent, :root, :parsed

    def initialize(value, parent, keyword, schema = parent)
      @value = value
      @parent = parent
      @root = parent.root
      @keyword = keyword
      @schema = schema
      @parsed = parse
    end

    def validate(_instance, _instance_location, _keyword_location, _context)
      nil
    end

    def absolute_keyword_location
      @absolute_keyword_location ||= "#{parent.absolute_keyword_location}/#{fragment_encode(escaped_keyword)}"
    end

    def schema_pointer
      @schema_pointer ||= "#{parent.schema_pointer}/#{escaped_keyword}"
    end

    def error_key
      keyword
    end

    def fetch(key)
      parsed.fetch(parsed.is_a?(Array) ? key.to_i : key)
    end

    def parsed_schema
      parsed.is_a?(Schema) ? parsed : nil
    end

  private

    def parse
      value
    end

    def subschema(value, keyword = nil, **options)
      options[:configuration] ||= schema.configuration
      options[:base_uri] ||= schema.base_uri
      options[:meta_schema] ||= schema.meta_schema
      options[:ref_resolver] ||= schema.ref_resolver
      options[:regexp_resolver] ||= schema.regexp_resolver
      Schema.new(value, self, root, keyword, **options)
    end
  end
end
