# frozen_string_literal: true

module OpenapiParameters
  ##
  # Represents a parameter in an OpenAPI operation.
  class Parameter
    # @param definition [Hash] The parameter definition. A string keyed Hash.
    def initialize(definition)
      @definition = definition
      @name = definition['name']
      @is_deep_object = style == 'deepObject'
      @converter = Converters[schema]
      check_supported!
    end

    attr_reader :name
    private attr_reader :definition

    def convert(value)
      @converter.call(value)
    end

    def deep_object?
      @is_deep_object
    end

    # @return [String] The location of the parameter in the request, "path", "query", "header" or "cookie".
    def location
      definition['in']
    end

    alias in location

    def schema
      return definition.dig('content', media_type, 'schema') if media_type

      definition['schema']
    end

    def media_type
      definition['content']&.keys&.first
    end

    def type
      schema && schema['type']
    end

    def primitive?
      type != 'object' && type != 'array'
    end

    def array?
      type == 'array'
    end

    EMPTY_BRACKETS = '[]'
    private_constant :EMPTY_BRACKETS

    def bracket_array?
      @bracket_array ||= array? && name.end_with?(EMPTY_BRACKETS)
    end

    def object?
      type == 'object' || style == 'deepObject' || schema&.key?('properties')
    end

    def style
      return definition['style'] if definition['style']

      DEFAULT_STYLE.fetch(location)
    end

    def required?
      return true if location == 'path'

      definition['required'] == true
    end

    def deprecated?
      definition['deprecated'] == true
    end

    def allow_reserved?
      definition['allowReserved'] == true
    end

    def explode?
      return definition['explode'] if definition.key?('explode')
      return true if style == 'form'

      false
    end

    private

    DEFAULT_STYLE = {
      'query' => 'form',
      'path' => 'simple',
      'header' => 'simple',
      'cookie' => 'form'
    }.freeze
    private_constant :DEFAULT_STYLE

    REF = '$ref'
    private_constant :REF

    def check_supported!
      return unless schema&.key?(REF)

      raise NotSupportedError,
            "Parameter schema with $ref is not supported: #{definition.inspect}"
    end
  end
end
