# frozen_string_literal: true
module JSONSchemer
  class OpenAPI
    def initialize(document, **options)
      @document = document

      version = document['openapi']
      case version
      when /\A3\.1\.\d+\z/
        @document_schema = JSONSchemer.openapi31_document
        meta_schema = document.fetch('jsonSchemaDialect') { OpenAPI31::BASE_URI.to_s }
      when /\A3\.0\.\d+\z/
        @document_schema = JSONSchemer.openapi30_document
        meta_schema = OpenAPI30::BASE_URI.to_s
      else
        raise UnsupportedOpenAPIVersion, version
      end

      @schema = JSONSchemer.schema(@document, :meta_schema => meta_schema, **options)
    end

    def valid?
      @document_schema.valid?(@document)
    end

    def validate(**options)
      @document_schema.validate(@document, **options)
    end

    def ref(value)
      @schema.ref(value)
    end

    def schema(name)
      ref("#/components/schemas/#{name}")
    end
  end
end
