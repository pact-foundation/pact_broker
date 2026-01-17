# frozen_string_literal: true
module JSONSchemer
  module OpenAPI30
    BASE_URI = URI('json-schemer://openapi30/schema')
    # https://spec.openapis.org/oas/v3.0.3#data-types
    FORMATS = OpenAPI31::FORMATS.merge(
      'int32' => proc { |instance, _format| !Draft4::Vocab::Validation::Type.valid_integer?(instance) || instance.floor.bit_length < 32 },
      'int64' => proc { |instance, _format| !Draft4::Vocab::Validation::Type.valid_integer?(instance) || instance.floor.bit_length < 64 },
      'byte' => proc { |instance, _value| !instance.is_a?(String) || ContentEncoding::BASE64.call(instance).first },
      'binary' => proc { |instance, _value| !instance.is_a?(String) || instance.encoding == Encoding::BINARY },
      'date' => Format::DATE
    )
    SCHEMA = {
      'id' => 'json-schemer://openapi30/schema',
      '$schema' => 'http://json-schema.org/draft-04/schema#',
      'allOf' => [
        { '$ref' => 'http://json-schema.org/draft-04/schema#' },
        {
          'oneOf' => [
            { '$ref' => 'https://spec.openapis.org/oas/3.0/schema/2021-09-28#/definitions/Schema' },
            { '$ref' => 'https://spec.openapis.org/oas/3.0/schema/2021-09-28#/definitions/Reference' }
          ]
        }
      ]
    }

    module Meta
      SCHEMAS = {
        Draft4::BASE_URI.dup.tap { |uri| uri.fragment = nil } => Draft4::SCHEMA,
        URI('https://spec.openapis.org/oas/3.0/schema/2021-09-28') => Document::SCHEMA
      }
    end
  end
end
