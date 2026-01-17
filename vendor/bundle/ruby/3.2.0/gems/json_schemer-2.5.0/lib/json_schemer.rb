# frozen_string_literal: true
require 'bigdecimal'
require 'forwardable'
require 'ipaddr'
require 'json'
require 'net/http'
require 'pathname'
require 'set'
require 'time'
require 'uri'

require 'hana'
require 'regexp_parser'
require 'simpleidn'

require 'json_schemer/version'
require 'json_schemer/format/duration'
require 'json_schemer/format/hostname'
require 'json_schemer/format/json_pointer'
require 'json_schemer/format/uri_template'
require 'json_schemer/format/email'
require 'json_schemer/format'
require 'json_schemer/content'
require 'json_schemer/errors'
require 'json_schemer/cached_resolver'
require 'json_schemer/ecma_regexp'
require 'json_schemer/location'
require 'json_schemer/result'
require 'json_schemer/output'
require 'json_schemer/keyword'
require 'json_schemer/draft202012/meta'
require 'json_schemer/draft202012/vocab/core'
require 'json_schemer/draft202012/vocab/applicator'
require 'json_schemer/draft202012/vocab/unevaluated'
require 'json_schemer/draft202012/vocab/validation'
require 'json_schemer/draft202012/vocab/format_annotation'
require 'json_schemer/draft202012/vocab/format_assertion'
require 'json_schemer/draft202012/vocab/content'
require 'json_schemer/draft202012/vocab/meta_data'
require 'json_schemer/draft202012/vocab'
require 'json_schemer/draft201909/meta'
require 'json_schemer/draft201909/vocab/core'
require 'json_schemer/draft201909/vocab/applicator'
require 'json_schemer/draft201909/vocab'
require 'json_schemer/draft7/meta'
require 'json_schemer/draft7/vocab/validation'
require 'json_schemer/draft7/vocab'
require 'json_schemer/draft6/meta'
require 'json_schemer/draft6/vocab'
require 'json_schemer/draft4/meta'
require 'json_schemer/draft4/vocab/validation'
require 'json_schemer/draft4/vocab'
require 'json_schemer/openapi31/meta'
require 'json_schemer/openapi31/vocab/base'
require 'json_schemer/openapi31/vocab'
require 'json_schemer/openapi31/document'
require 'json_schemer/openapi30/document'
require 'json_schemer/openapi30/meta'
require 'json_schemer/openapi30/vocab/base'
require 'json_schemer/openapi30/vocab'
require 'json_schemer/openapi'
require 'json_schemer/configuration'
require 'json_schemer/resources'
require 'json_schemer/schema'

module JSONSchemer
  class UnsupportedOpenAPIVersion < StandardError; end
  class UnknownRef < StandardError; end
  class UnknownFormat < StandardError; end
  class UnknownVocabulary < StandardError; end
  class UnknownContentEncoding < StandardError; end
  class UnknownContentMediaType < StandardError; end
  class UnknownOutputFormat < StandardError; end
  class InvalidRefResolution < StandardError; end
  class InvalidRefPointer < StandardError; end
  class InvalidRegexpResolution < StandardError; end
  class InvalidFileURI < StandardError; end
  class InvalidEcmaRegexp < StandardError; end

  VOCABULARIES = {
    'https://json-schema.org/draft/2020-12/vocab/core' => Draft202012::Vocab::CORE,
    'https://json-schema.org/draft/2020-12/vocab/applicator' => Draft202012::Vocab::APPLICATOR,
    'https://spec.openapis.org/oas/3.1/vocab/base' => OpenAPI31::Vocab::BASE,
    'https://json-schema.org/draft/2020-12/vocab/unevaluated' => Draft202012::Vocab::UNEVALUATED,
    'https://json-schema.org/draft/2020-12/vocab/validation' => Draft202012::Vocab::VALIDATION,
    'https://json-schema.org/draft/2020-12/vocab/format-annotation' => Draft202012::Vocab::FORMAT_ANNOTATION,
    'https://json-schema.org/draft/2020-12/vocab/format-assertion' => Draft202012::Vocab::FORMAT_ASSERTION,
    'https://json-schema.org/draft/2020-12/vocab/content' => Draft202012::Vocab::CONTENT,
    'https://json-schema.org/draft/2020-12/vocab/meta-data' => Draft202012::Vocab::META_DATA,

    'https://json-schema.org/draft/2019-09/vocab/core' => Draft201909::Vocab::CORE,
    'https://json-schema.org/draft/2019-09/vocab/applicator' => Draft201909::Vocab::APPLICATOR,
    'https://json-schema.org/draft/2019-09/vocab/validation' => Draft201909::Vocab::VALIDATION,
    'https://json-schema.org/draft/2019-09/vocab/format' => Draft201909::Vocab::FORMAT,
    'https://json-schema.org/draft/2019-09/vocab/content' => Draft201909::Vocab::CONTENT,
    'https://json-schema.org/draft/2019-09/vocab/meta-data' => Draft201909::Vocab::META_DATA,

    'json-schemer://draft7' => Draft7::Vocab::ALL,
    'json-schemer://draft6' => Draft6::Vocab::ALL,
    'json-schemer://draft4' => Draft4::Vocab::ALL,
    'json-schemer://openapi30' => OpenAPI30::Vocab::BASE
  }
  VOCABULARY_ORDER = VOCABULARIES.transform_values.with_index { |_vocabulary, index| index }

  WINDOWS_URI_PATH_REGEX = /\A\/[a-z]:/i

  # :nocov:
  URI_PARSER = URI.const_defined?(:RFC2396_PARSER) ? URI::RFC2396_PARSER : URI::DEFAULT_PARSER
  # :nocov:

  FILE_URI_REF_RESOLVER = proc do |uri|
    raise InvalidFileURI, 'must use `file` scheme' unless uri.scheme == 'file'
    raise InvalidFileURI, 'cannot have a host (use `file:///`)' if uri.host && !uri.host.empty?
    path = uri.path
    path = path[1..-1] if path.match?(WINDOWS_URI_PATH_REGEX)
    JSON.parse(File.read(URI_PARSER.unescape(path)))
  end

  class << self
    def schema(schema, **options)
      schema = resolve(schema, options)
      Schema.new(schema, **options)
    end

    def valid_schema?(schema, **options)
      schema = resolve(schema, options)
      meta_schema(schema, options).valid?(schema, **options.slice(:output_format, :resolve_enumerators, :access_mode))
    end

    def validate_schema(schema, **options)
      schema = resolve(schema, options)
      meta_schema(schema, options).validate(schema, **options.slice(:output_format, :resolve_enumerators, :access_mode))
    end

    def draft202012
      @draft202012 ||= Schema.new(
        Draft202012::SCHEMA,
        :base_uri => Draft202012::BASE_URI,
        :formats => Draft202012::FORMATS,
        :content_encodings => Draft202012::CONTENT_ENCODINGS,
        :content_media_types => Draft202012::CONTENT_MEDIA_TYPES,
        :ref_resolver => Draft202012::Meta::SCHEMAS.to_proc,
        :regexp_resolver => 'ecma'
      )
    end

    def draft201909
      @draft201909 ||= Schema.new(
        Draft201909::SCHEMA,
        :base_uri => Draft201909::BASE_URI,
        :formats => Draft201909::FORMATS,
        :content_encodings => Draft201909::CONTENT_ENCODINGS,
        :content_media_types => Draft201909::CONTENT_MEDIA_TYPES,
        :ref_resolver => Draft201909::Meta::SCHEMAS.to_proc,
        :regexp_resolver => 'ecma'
      )
    end

    def draft7
      @draft7 ||= Schema.new(
        Draft7::SCHEMA,
        :vocabulary => { 'json-schemer://draft7' => true },
        :base_uri => Draft7::BASE_URI,
        :formats => Draft7::FORMATS,
        :content_encodings => Draft7::CONTENT_ENCODINGS,
        :content_media_types => Draft7::CONTENT_MEDIA_TYPES,
        :regexp_resolver => 'ecma'
      )
    end

    def draft6
      @draft6 ||= Schema.new(
        Draft6::SCHEMA,
        :vocabulary => { 'json-schemer://draft6' => true },
        :base_uri => Draft6::BASE_URI,
        :formats => Draft6::FORMATS,
        :content_encodings => Draft6::CONTENT_ENCODINGS,
        :content_media_types => Draft6::CONTENT_MEDIA_TYPES,
        :regexp_resolver => 'ecma'
      )
    end

    def draft4
      @draft4 ||= Schema.new(
        Draft4::SCHEMA,
        :vocabulary => { 'json-schemer://draft4' => true },
        :base_uri => Draft4::BASE_URI,
        :formats => Draft4::FORMATS,
        :content_encodings => Draft4::CONTENT_ENCODINGS,
        :content_media_types => Draft4::CONTENT_MEDIA_TYPES,
        :regexp_resolver => 'ecma'
      )
    end

    def openapi31
      @openapi31 ||= Schema.new(
        OpenAPI31::SCHEMA,
        :base_uri => OpenAPI31::BASE_URI,
        :formats => OpenAPI31::FORMATS,
        :ref_resolver => OpenAPI31::Meta::SCHEMAS.to_proc,
        :regexp_resolver => 'ecma'
      )
    end

    def openapi30
      @openapi30 ||= Schema.new(
        OpenAPI30::SCHEMA,
        :vocabulary => {
          'json-schemer://draft4' => true,
          'json-schemer://openapi30' => true
        },
        :base_uri => OpenAPI30::BASE_URI,
        :formats => OpenAPI30::FORMATS,
        :ref_resolver => OpenAPI30::Meta::SCHEMAS.to_proc,
        :regexp_resolver => 'ecma'
      )
    end

    def openapi31_document
      @openapi31_document ||= Schema.new(
        OpenAPI31::Document::SCHEMA_BASE,
        :ref_resolver => OpenAPI31::Document::SCHEMAS.to_proc,
        :regexp_resolver => 'ecma'
      )
    end

    def openapi30_document
      @openapi30_document ||= Schema.new(
        OpenAPI30::Document::SCHEMA,
        :ref_resolver => OpenAPI30::Document::SCHEMAS.to_proc,
        :regexp_resolver => 'ecma'
      )
    end

    def openapi(document, **options)
      OpenAPI.new(document, **options)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

  private

    def resolve(schema, options)
      case schema
      when String
        JSON.parse(schema)
      when Pathname
        base_uri = URI.parse(File.join('file:', URI_PARSER.escape(schema.realpath.to_s)))
        options[:base_uri] = base_uri
        if options.key?(:ref_resolver)
          FILE_URI_REF_RESOLVER.call(base_uri)
        else
          ref_resolver = CachedResolver.new(&FILE_URI_REF_RESOLVER)
          options[:ref_resolver] = ref_resolver
          ref_resolver.call(base_uri)
        end
      else
        schema
      end
    end

    def meta_schema(schema, options)
      parseable_schema = {}
      if schema.is_a?(Hash)
        meta_schema = schema['$schema'] || schema[:'$schema']
        parseable_schema['$schema'] = meta_schema if meta_schema.is_a?(String)
      end
      schema(parseable_schema, **options).meta_schema
    end
  end

  META_SCHEMA_CALLABLES_BY_BASE_URI_STR = {
    Draft202012::BASE_URI.to_s => method(:draft202012),
    Draft201909::BASE_URI.to_s => method(:draft201909),
    Draft7::BASE_URI.to_s => method(:draft7),
    Draft6::BASE_URI.to_s => method(:draft6),
    Draft4::BASE_URI.to_s => method(:draft4),
    # version-less $schema deprecated after Draft 4
    'http://json-schema.org/schema#' => method(:draft4),
    OpenAPI31::BASE_URI.to_s => method(:openapi31),
    OpenAPI30::BASE_URI.to_s => method(:openapi30)
  }.freeze

  META_SCHEMAS_BY_BASE_URI_STR = Hash.new do |hash, base_uri_str|
    next unless META_SCHEMA_CALLABLES_BY_BASE_URI_STR.key?(base_uri_str)
    hash[base_uri_str] = META_SCHEMA_CALLABLES_BY_BASE_URI_STR.fetch(base_uri_str).call
  end
end
