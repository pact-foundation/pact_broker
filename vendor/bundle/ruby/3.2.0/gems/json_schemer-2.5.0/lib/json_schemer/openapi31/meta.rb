# frozen_string_literal: true
module JSONSchemer
  module OpenAPI31
    BASE_URI = URI('https://spec.openapis.org/oas/3.1/dialect/base')
    # https://spec.openapis.org/oas/v3.1.0#data-types
    FORMATS = {
      'int32' => proc { |instance, _format| !Draft202012::Vocab::Validation::Type.valid_integer?(instance) || instance.floor.bit_length < 32 },
      'int64' => proc { |instance, _format| !Draft202012::Vocab::Validation::Type.valid_integer?(instance) || instance.floor.bit_length < 64 },
      'float' => proc { |instance, _format| !instance.is_a?(Numeric) || instance.is_a?(Float) },
      'double' => proc { |instance, _format| !instance.is_a?(Numeric) || instance.is_a?(Float) },
      'password' => proc { |_instance, _format| true }
    }
    SCHEMA = {
      '$id' => 'https://spec.openapis.org/oas/3.1/dialect/base',
      '$schema' => 'https://json-schema.org/draft/2020-12/schema',

      'title' => 'OpenAPI 3.1 Schema Object Dialect',
      'description' => 'A JSON Schema dialect describing schemas found in OpenAPI documents',

      '$vocabulary' => {
        'https://json-schema.org/draft/2020-12/vocab/core' => true,
        'https://json-schema.org/draft/2020-12/vocab/applicator' => true,
        'https://json-schema.org/draft/2020-12/vocab/unevaluated' => true,
        'https://json-schema.org/draft/2020-12/vocab/validation' => true,
        'https://json-schema.org/draft/2020-12/vocab/meta-data' => true,
        'https://json-schema.org/draft/2020-12/vocab/format-annotation' => true,
        'https://json-schema.org/draft/2020-12/vocab/content' => true,
        'https://spec.openapis.org/oas/3.1/vocab/base' => false
      },

      '$dynamicAnchor' => 'meta',

      'allOf' => [
        { '$ref' => 'https://json-schema.org/draft/2020-12/schema' },
        { '$ref' => 'https://spec.openapis.org/oas/3.1/meta/base' }
      ]
    }


    module Meta
      BASE = {
        '$id' => 'https://spec.openapis.org/oas/3.1/meta/base',
        '$schema' => 'https://json-schema.org/draft/2020-12/schema',

        'title' => 'OAS Base vocabulary',
        'description' => 'A JSON Schema Vocabulary used in the OpenAPI Schema Dialect',

        '$vocabulary' => {
          'https://spec.openapis.org/oas/3.1/vocab/base' => true
        },

        '$dynamicAnchor' => 'meta',

        'type' => ['object', 'boolean'],
        'properties' => {
          'example' => true,
          'discriminator' => { '$ref' => '#/$defs/discriminator' },
          'externalDocs' => { '$ref' => '#/$defs/external-docs' },
          'xml' => { '$ref' => '#/$defs/xml' }
        },

        '$defs' => {
          'extensible' => {
            'patternProperties' => {
              '^x-' => true
            }
          },

          'discriminator' => {
            '$ref' => '#/$defs/extensible',
            'type' => 'object',
            'properties' => {
              'propertyName' => {
                'type' => 'string'
              },
              'mapping' => {
                'type' => 'object',
                'additionalProperties' => {
                  'type' => 'string'
                }
              }
            },
            'required' => ['propertyName'],
            'unevaluatedProperties' => false
          },

          'external-docs' => {
            '$ref' => '#/$defs/extensible',
            'type' => 'object',
            'properties' => {
              'url' => {
                'type' => 'string',
                'format' => 'uri-reference'
              },
              'description' => {
                'type' => 'string'
              }
            },
            'required' => ['url'],
            'unevaluatedProperties' => false
          },

          'xml' => {
            '$ref' => '#/$defs/extensible',
            'type' => 'object',
            'properties' => {
              'name' => {
                'type' => 'string'
              },
              'namespace' => {
                'type' => 'string',
                'format' => 'uri'
              },
              'prefix' => {
                'type' => 'string'
              },
              'attribute' => {
                'type' => 'boolean'
              },
              'wrapped' => {
                'type' => 'boolean'
              }
            },
            'unevaluatedProperties' => false
          }
        }
      }


      SCHEMAS = Draft202012::Meta::SCHEMAS.merge(
        Draft202012::BASE_URI => Draft202012::SCHEMA,
        URI('https://spec.openapis.org/oas/3.1/meta/base') => BASE
      )
    end
  end
end
