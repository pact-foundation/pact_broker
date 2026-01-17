# frozen_string_literal: true
module JSONSchemer
  module Draft202012
    BASE_URI = URI('https://json-schema.org/draft/2020-12/schema')
    FORMATS = {
      'date-time' => Format::DATE_TIME,
      'date' => Format::DATE,
      'time' => Format::TIME,
      'duration' => Format::DURATION,
      'email' => Format::EMAIL,
      'idn-email' => Format::IDN_EMAIL,
      'hostname' => Format::HOSTNAME,
      'idn-hostname' => Format::IDN_HOSTNAME,
      'ipv4' => Format::IPV4,
      'ipv6' => Format::IPV6,
      'uri' => Format::URI,
      'uri-reference' => Format::URI_REFERENCE,
      'iri' => Format::IRI,
      'iri-reference' => Format::IRI_REFERENCE,
      'uuid' => Format::UUID,
      'uri-template' => Format::URI_TEMPLATE,
      'json-pointer' => Format::JSON_POINTER,
      'relative-json-pointer' => Format::RELATIVE_JSON_POINTER,
      'regex' => Format::REGEX
    }
    CONTENT_ENCODINGS = {
      'base64' => ContentEncoding::BASE64
    }
    CONTENT_MEDIA_TYPES = {
      'application/json' => ContentMediaType::JSON
    }
    SCHEMA = {
      '$schema' => 'https://json-schema.org/draft/2020-12/schema',
      '$id' => 'https://json-schema.org/draft/2020-12/schema',
      '$vocabulary' => {
        'https://json-schema.org/draft/2020-12/vocab/core' => true,
        'https://json-schema.org/draft/2020-12/vocab/applicator' => true,
        'https://json-schema.org/draft/2020-12/vocab/unevaluated' => true,
        'https://json-schema.org/draft/2020-12/vocab/validation' => true,
        'https://json-schema.org/draft/2020-12/vocab/meta-data' => true,
        'https://json-schema.org/draft/2020-12/vocab/format-annotation' => true,
        'https://json-schema.org/draft/2020-12/vocab/content' => true
      },
      '$dynamicAnchor' => 'meta',
      'title' => 'Core and Validation specifications meta-schema',
      'allOf' => [
        {'$ref' => 'meta/core'},
        {'$ref' => 'meta/applicator'},
        {'$ref' => 'meta/unevaluated'},
        {'$ref' => 'meta/validation'},
        {'$ref' => 'meta/meta-data'},
        {'$ref' => 'meta/format-annotation'},
        {'$ref' => 'meta/content'}
      ],
      'type' => ['object', 'boolean'],
      '$comment' => 'This meta-schema also defines keywords that have appeared in previous drafts in order to prevent incompatible extensions as they remain in common use.',
      'properties' => {
        'definitions' => {
          '$comment' => '"definitions" has been replaced by "$defs".',
          'type' => 'object',
          'additionalProperties' => { '$dynamicRef' => '#meta' },
          'deprecated' => true,
          'default' => {}
        },
        'dependencies' => {
          '$comment' => '"dependencies" has been split and replaced by "dependentSchemas" and "dependentRequired" in order to serve their differing semantics.',
          'type' => 'object',
          'additionalProperties' => {
            'anyOf' => [
              { '$dynamicRef' => '#meta' },
              { '$ref' => 'meta/validation#/$defs/stringArray' }
            ]
          },
          'deprecated' => true,
          'default' => {}
        },
        '$recursiveAnchor' => {
          '$comment' => '"$recursiveAnchor" has been replaced by "$dynamicAnchor".',
          '$ref' => 'meta/core#/$defs/anchorString',
          'deprecated' => true
        },
        '$recursiveRef' => {
          '$comment' => '"$recursiveRef" has been replaced by "$dynamicRef".',
          '$ref' => 'meta/core#/$defs/uriReferenceString',
          'deprecated' => true
        }
      }
    }

    module Meta
      CORE = {
        '$schema' => 'https://json-schema.org/draft/2020-12/schema',
        '$id' => 'https://json-schema.org/draft/2020-12/meta/core',
        '$dynamicAnchor' => 'meta',
        'title' => 'Core vocabulary meta-schema',
        'type' => ['object', 'boolean'],
        'properties' => {
          '$id' => {
            '$ref' => '#/$defs/uriReferenceString',
            '$comment' => 'Non-empty fragments not allowed.',
            'pattern' => '^[^#]*#?$'
          },
          '$schema' => { '$ref' => '#/$defs/uriString' },
          '$ref' => { '$ref' => '#/$defs/uriReferenceString' },
          '$anchor' => { '$ref' => '#/$defs/anchorString' },
          '$dynamicRef' => { '$ref' => '#/$defs/uriReferenceString' },
          '$dynamicAnchor' => { '$ref' => '#/$defs/anchorString' },
          '$vocabulary' => {
            'type' => 'object',
            'propertyNames' => { '$ref' => '#/$defs/uriString' },
            'additionalProperties' => {
              'type' => 'boolean'
            }
          },
          '$comment' => {
            'type' => 'string'
          },
          '$defs' => {
            'type' => 'object',
            'additionalProperties' => { '$dynamicRef' => '#meta' }
          }
        },
        '$defs' => {
          'anchorString' => {
            'type' => 'string',
            'pattern' => '^[A-Za-z_][-A-Za-z0-9._]*$'
          },
          'uriString' => {
            'type' => 'string',
            'format' => 'uri'
          },
          'uriReferenceString' => {
            'type' => 'string',
            'format' => 'uri-reference'
          }
        }
      }
      APPLICATOR = {
        '$schema' => 'https://json-schema.org/draft/2020-12/schema',
        '$id' => 'https://json-schema.org/draft/2020-12/meta/applicator',
        '$dynamicAnchor' => 'meta',
        'title' => 'Applicator vocabulary meta-schema',
        'type' => ['object', 'boolean'],
        'properties' => {
          'prefixItems' => { '$ref' => '#/$defs/schemaArray' },
          'items' => { '$dynamicRef' => '#meta' },
          'contains' => { '$dynamicRef' => '#meta' },
          'additionalProperties' => { '$dynamicRef' => '#meta' },
          'properties' => {
            'type' => 'object',
            'additionalProperties' => { '$dynamicRef' => '#meta' },
            'default' => {}
          },
          'patternProperties' => {
            'type' => 'object',
            'additionalProperties' => { '$dynamicRef' => '#meta' },
            'propertyNames' => { 'format' => 'regex' },
            'default' => {}
          },
          'dependentSchemas' => {
            'type' => 'object',
            'additionalProperties' => { '$dynamicRef' => '#meta' },
            'default' => {}
          },
          'propertyNames' => { '$dynamicRef' => '#meta' },
          'if' => { '$dynamicRef' => '#meta' },
          'then' => { '$dynamicRef' => '#meta' },
          'else' => { '$dynamicRef' => '#meta' },
          'allOf' => { '$ref' => '#/$defs/schemaArray' },
          'anyOf' => { '$ref' => '#/$defs/schemaArray' },
          'oneOf' => { '$ref' => '#/$defs/schemaArray' },
          'not' => { '$dynamicRef' => '#meta' }
        },
        '$defs' => {
          'schemaArray' => {
            'type' => 'array',
            'minItems' => 1,
            'items' => { '$dynamicRef' => '#meta' }
          }
        }
      }
      UNEVALUATED = {
        '$schema' => 'https://json-schema.org/draft/2020-12/schema',
        '$id' => 'https://json-schema.org/draft/2020-12/meta/unevaluated',
        '$dynamicAnchor' => 'meta',
        'title' => 'Unevaluated applicator vocabulary meta-schema',
        'type' => ['object', 'boolean'],
        'properties' => {
          'unevaluatedItems' => { '$dynamicRef' => '#meta' },
          'unevaluatedProperties' => { '$dynamicRef' => '#meta' }
        }
      }
      VALIDATION = {
        '$schema' => 'https://json-schema.org/draft/2020-12/schema',
        '$id' => 'https://json-schema.org/draft/2020-12/meta/validation',
        '$dynamicAnchor' => 'meta',
        'title' => 'Validation vocabulary meta-schema',
        'type' => ['object', 'boolean'],
        'properties' => {
          'type' => {
            'anyOf' => [
              { '$ref' => '#/$defs/simpleTypes' },
              {
                'type' => 'array',
                'items' => { '$ref' => '#/$defs/simpleTypes' },
                'minItems' => 1,
                'uniqueItems' => true
              }
            ]
          },
          'const' => true,
          'enum' => {
            'type' => 'array',
            'items' => true
          },
          'multipleOf' => {
            'type' => 'number',
            'exclusiveMinimum' => 0
          },
          'maximum' => {
            'type' => 'number'
          },
          'exclusiveMaximum' => {
            'type' => 'number'
          },
          'minimum' => {
            'type' => 'number'
          },
          'exclusiveMinimum' => {
            'type' => 'number'
          },
          'maxLength' => { '$ref' => '#/$defs/nonNegativeInteger' },
          'minLength' => { '$ref' => '#/$defs/nonNegativeIntegerDefault0' },
          'pattern' => {
            'type' => 'string',
            'format' => 'regex'
          },
          'maxItems' => { '$ref' => '#/$defs/nonNegativeInteger' },
          'minItems' => { '$ref' => '#/$defs/nonNegativeIntegerDefault0' },
          'uniqueItems' => {
            'type' => 'boolean',
            'default' => false
          },
          'maxContains' => { '$ref' => '#/$defs/nonNegativeInteger' },
          'minContains' => {
            '$ref' => '#/$defs/nonNegativeInteger',
            'default' => 1
          },
          'maxProperties' => { '$ref' => '#/$defs/nonNegativeInteger' },
          'minProperties' => { '$ref' => '#/$defs/nonNegativeIntegerDefault0' },
          'required' => { '$ref' => '#/$defs/stringArray' },
          'dependentRequired' => {
            'type' => 'object',
            'additionalProperties' => {
              '$ref' => '#/$defs/stringArray'
            }
          }
        },
        '$defs' => {
          'nonNegativeInteger' => {
            'type' => 'integer',
            'minimum' => 0
          },
          'nonNegativeIntegerDefault0' => {
            '$ref' => '#/$defs/nonNegativeInteger',
            'default' => 0
          },
          'simpleTypes' => {
            'enum' => [
              'array',
              'boolean',
              'integer',
              'null',
              'number',
              'object',
              'string'
            ]
          },
          'stringArray' => {
            'type' => 'array',
            'items' => { 'type' => 'string' },
            'uniqueItems' => true,
            'default' => []
          }
        }
      }
      META_DATA = {
        '$schema' => 'https://json-schema.org/draft/2020-12/schema',
        '$id' => 'https://json-schema.org/draft/2020-12/meta/meta-data',
        '$dynamicAnchor' => 'meta',
        'title' => 'Meta-data vocabulary meta-schema',
        'type' => ['object', 'boolean'],
        'properties' => {
          'title' => {
            'type' => 'string'
          },
          'description' => {
            'type' => 'string'
          },
          'default' => true,
          'deprecated' => {
            'type' => 'boolean',
            'default' => false
          },
          'readOnly' => {
            'type' => 'boolean',
            'default' => false
          },
          'writeOnly' => {
            'type' => 'boolean',
            'default' => false
          },
          'examples' => {
            'type' => 'array',
            'items' => true
          }
        }
      }
      FORMAT_ANNOTATION = {
        '$schema' => 'https://json-schema.org/draft/2020-12/schema',
        '$id' => 'https://json-schema.org/draft/2020-12/meta/format-annotation',
        '$dynamicAnchor' => 'meta',
        'title' => 'Format vocabulary meta-schema for annotation results',
        'type' => ['object', 'boolean'],
        'properties' => {
          'format' => { 'type' => 'string' }
        }
      }
      FORMAT_ASSERTION = {
        '$schema' => 'https://json-schema.org/draft/2020-12/schema',
        '$id' => 'https://json-schema.org/draft/2020-12/meta/format-assertion',
        '$dynamicAnchor' => 'meta',
        'title' => 'Format vocabulary meta-schema for assertion results',
        'type' => ['object', 'boolean'],
        'properties' => {
          'format' => { 'type' => 'string' }
        }
      }
      CONTENT = {
        '$schema' => 'https://json-schema.org/draft/2020-12/schema',
        '$id' => 'https://json-schema.org/draft/2020-12/meta/content',
        '$dynamicAnchor' => 'meta',
        'title' => 'Content vocabulary meta-schema',
        'type' => ['object', 'boolean'],
        'properties' => {
          'contentEncoding' => { 'type' => 'string' },
          'contentMediaType' => { 'type' => 'string' },
          'contentSchema' => { '$dynamicRef' => '#meta' }
        }
      }

      SCHEMAS = {
        URI('https://json-schema.org/draft/2020-12/meta/core') => CORE,
        URI('https://json-schema.org/draft/2020-12/meta/applicator') => APPLICATOR,
        URI('https://json-schema.org/draft/2020-12/meta/unevaluated') => UNEVALUATED,
        URI('https://json-schema.org/draft/2020-12/meta/validation') => VALIDATION,
        URI('https://json-schema.org/draft/2020-12/meta/meta-data') => META_DATA,
        URI('https://json-schema.org/draft/2020-12/meta/format-annotation') => FORMAT_ANNOTATION,
        URI('https://json-schema.org/draft/2020-12/meta/format-assertion') => FORMAT_ASSERTION,
        URI('https://json-schema.org/draft/2020-12/meta/content') => CONTENT
      }
    end
  end
end
