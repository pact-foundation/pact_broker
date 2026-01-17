# frozen_string_literal: true

require 'json_schemer'

require_relative 'failure'
require_relative 'router'
require_relative 'header'
require_relative 'request'
require_relative 'response'
require_relative 'schema/hash'
require_relative 'ref_resolver'

module OpenapiFirst
  # Builds parts of a Definition
  # This knows how to read a resolved OpenAPI document and build {Request} and {Response} objects.
  class Builder # rubocop:disable Metrics/ClassLength
    REQUEST_METHODS = %w[get head post put patch delete trace options query].freeze

    # Builds a router from a resolved OpenAPI document.
    # @param contents [Hash] The OpenAPI document Hash.
    # @param config [OpenapiFirst::Configuration] The configuration object.
    def self.build_router(contents, filepath:, config:)
      new(contents, filepath:, config:).router
    end

    def initialize(contents, filepath:, config:)
      meta_schema = detect_meta_schema(contents, filepath)
      @schemer_configuration = build_schemer_config(filepath:, meta_schema:)
      @config = config
      @contents = RefResolver.for(contents, filepath:)
    end

    attr_reader :config
    private attr_reader :schemer_configuration

    def build_schemer_config(filepath:, meta_schema:)
      result = JSONSchemer.configuration.clone
      dir = (filepath && File.absolute_path(File.dirname(filepath))) || Dir.pwd
      result.base_uri = URI::File.build({ path: "#{dir}/" })
      result.ref_resolver = JSONSchemer::CachedResolver.new do |uri|
        FileLoader.load(uri.path)
      end
      result.meta_schema = meta_schema
      result.insert_property_defaults = true
      result
    end

    def detect_meta_schema(document, filepath)
      # Copied from JSONSchemer 🙇🏻‍♂️
      version = document['openapi']
      case version
      when /\A3\.1\.\d+\z/
        document.fetch('jsonSchemaDialect') { JSONSchemer::OpenAPI31::BASE_URI.to_s }
      when /\A3\.0\.\d+\z/
        JSONSchemer::OpenAPI30::BASE_URI.to_s
      else
        raise Error, "Unsupported OpenAPI version #{version.inspect} #{filepath}"
      end
    end

    def router # rubocop:disable Metrics/MethodLength
      router = OpenapiFirst::Router.new
      @contents.fetch('paths').each do |path, path_item_object|
        path_parameters = path_item_object['parameters'] || []
        path_item_object.resolved.keys.intersection(REQUEST_METHODS).map do |request_method|
          operation_object = path_item_object[request_method]
          operation_parameters = operation_object['parameters'] || []
          parameters = parse_parameters(operation_parameters.chain(path_parameters))

          build_requests(path:, request_method:, operation_object:,
                         parameters:).each do |request|
            router.add_request(
              request,
              request_method:,
              path:,
              content_type: request.content_type,
              allow_empty_content: request.allow_empty_content?
            )
            build_responses(request:, responses: operation_object['responses']).each do |response|
              router.add_response(
                response,
                request_method:,
                path:,
                status: response.status,
                response_content_type: response.content_type
              )
            end
          end
        end
      end
      router
    end

    def parse_parameters(parameters)
      grouped_parameters = group_parameters(parameters)
      ParsedParameters.new(
        query: resolve_parameters(grouped_parameters[:query]),
        path: resolve_parameters(grouped_parameters[:path]),
        cookie: resolve_parameters(grouped_parameters[:cookie]),
        header: resolve_parameters(grouped_parameters[:header]),
        query_schema: build_parameter_schema(grouped_parameters[:query]),
        path_schema: build_parameter_schema(grouped_parameters[:path]),
        cookie_schema: build_parameter_schema(grouped_parameters[:cookie]),
        header_schema: build_parameter_schema(grouped_parameters[:header])
      )
    end

    def resolve_parameters(parameters)
      parameters&.map do |parameter|
        result = parameter.resolved
        result['schema'] = parameter['schema'].resolved
        result
      end.to_a
    end

    def build_parameter_schema(parameters)
      return unless parameters

      required = []
      schemas = parameters.each_with_object({}) do |parameter, result|
        schema = parameter['schema'].schema(configuration: schemer_configuration)
        name = parameter['name']&.value
        required << name if parameter['required']&.value
        result[name] = schema if schema
      end

      Schema::Hash.new(schemas, required:, configuration: schemer_configuration,
                                after_property_validation: config.hooks[:after_request_parameter_property_validation])
    end

    def build_requests(path:, request_method:, operation_object:, parameters:)
      content_objects = operation_object.dig('requestBody', 'content')
      if content_objects.nil?
        return [
          request_without_body(path:, request_method:, parameters:, operation_object:)
        ]
      end
      required_body = operation_object['requestBody']&.resolved&.fetch('required', false) == true
      content_objects.map do |content_type, content_object|
        content_schema = content_object['schema'].schema(
          configuration: schemer_configuration,
          after_property_validation: config.hooks[:after_request_body_property_validation]
        )
        Request.new(path:, request_method:, parameters:,
                    operation_object: operation_object.resolved,
                    content_type:,
                    content_schema:,
                    required_body:,
                    key: [path, request_method, content_type].join(':'))
      end
    end

    def request_without_body(path:, request_method:, parameters:, operation_object:)
      Request.new(path:, request_method:, parameters:,
                  operation_object: operation_object.resolved,
                  content_type: nil,
                  content_schema: nil,
                  required_body: false,
                  key: [path, request_method, nil].join(':'))
    end

    def build_responses(responses:, request:)
      return [] unless responses

      responses.flat_map do |status, response_object|
        headers = build_response_headers(response_object['headers'])
        response_object['content']&.map do |content_type, content_object|
          content_schema = content_object['schema'].schema(configuration: schemer_configuration)
          Response.new(status:,
                       headers:,
                       content_type:,
                       content_schema:,
                       key: [request.key, status, content_type].join(':'))
        end || Response.new(status:, headers:, content_type: nil,
                            content_schema: nil, key: [request.key, status, nil].join(':'))
      end
    end

    IGNORED_HEADER_PARAMETERS = Set['Content-Type', 'Accept', 'Authorization'].freeze
    private_constant :IGNORED_HEADER_PARAMETERS

    def build_response_headers(headers_object)
      return if headers_object.nil?

      result = []
      headers_object.each do |name, header|
        next if header['schema'].nil?
        next if IGNORED_HEADER_PARAMETERS.include?(name)

        header = Header.new(
          name:,
          schema: header['schema'].schema(configuration: schemer_configuration),
          required?: header['required']&.value == true,
          node: header
        )
        result << header
      end
      result
    end

    def group_parameters(parameter_definitions)
      result = {}
      parameter_definitions&.each do |parameter|
        (result[parameter['in']&.value&.to_sym] ||= []) << parameter
      end
      result[:header]&.reject! { IGNORED_HEADER_PARAMETERS.include?(_1['name']&.value) }
      result
    end

    ParsedParameters = Data.define(:path, :query, :header, :cookie, :path_schema, :query_schema, :header_schema,
                                   :cookie_schema)
    private_constant :ParsedParameters
  end
end
