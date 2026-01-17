# frozen_string_literal: true

require_relative 'builder'
require 'forwardable'

module OpenapiFirst
  # Represents an OpenAPI API Description document
  # This is returned by OpenapiFirst.load.
  class Definition
    extend Forwardable

    # @return [String,nil]
    attr_reader :filepath
    # @return [Configuration]
    attr_reader :config
    # @return [Enumerable[String]]
    attr_reader :paths
    # @return [Router]
    attr_reader :router

    # @param contents [Hash] The OpenAPI document.
    # @param filepath [String] The file path of the OpenAPI document.
    def initialize(contents, filepath = nil)
      @filepath = filepath
      @config = OpenapiFirst.configuration.clone
      yield @config if block_given?
      @config.freeze
      @router = Builder.build_router(contents, filepath:, config:)
      @resolved = contents
      @paths = @router.routes.map(&:path).to_a.uniq # TODO: Refactor
    end

    # Gives access to the raw resolved Hash. Like `mydefinition['components'].dig('schemas', 'Stations')`
    # @!method [](key)
    # @return [Hash]
    def_delegators :@resolved, :[]

    # Returns an Enumerable of available Routes for this API description.
    # @!method routes
    # @return [Enumerable[Router::Route]]
    def_delegators :@router, :routes

    # Returns a unique identifier for this API definition
    # @return [String] A unique key for this API definition
    def key
      return filepath if filepath

      info = self['info'] || {}
      title = info['title']
      version = info['version']

      if title.nil? || version.nil?
        raise ArgumentError,
              "Cannot generate key for the OpenAPI document because 'info.title' or 'info.version' is missing. " \
              'Please add these fields to your OpenAPI document.'
      end

      "#{title} @ #{version}"
    end

    # Validates the request against the API description.
    # @param [Rack::Request] request The Rack request object.
    # @param [Boolean] raise_error Whether to raise an error if validation fails.
    # @return [ValidatedRequest] The validated request object.
    def validate_request(request, raise_error: false)
      route = @router.match(request.request_method, resolve_path(request), content_type: request.content_type)
      if route.error
        ValidatedRequest.new(request, error: route.error)
      else
        route.request_definition.validate(request, route_params: route.params)
      end.tap do |validated|
        @config.hooks[:after_request_validation].each { |hook| hook.call(validated, self) }
        raise validated.error.exception(validated) if validated.error && raise_error
      end
    end

    # Validates the response against the API description.
    # @param rack_request [Rack::Request] The Rack request object.
    # @param rack_response [Rack::Response] The Rack response object.
    # @param raise_error [Boolean] Whethir to raise an error if validation fails.
    # @return [ValidatedResponse] The validated response object.
    def validate_response(rack_request, rack_response, raise_error: false)
      route = @router.match(rack_request.request_method, resolve_path(rack_request),
                            content_type: rack_request.content_type)
      return if route.error # Skip response validation for unknown requests

      response_match = route.match_response(status: rack_response.status, content_type: rack_response.content_type)
      error = response_match.error
      validated = if error
                    ValidatedResponse.new(rack_response, error:)
                  else
                    response_match.response.validate(rack_response)
                  end
      @config.hooks[:after_response_validation]&.each { |hook| hook.call(validated, rack_request, self) }
      raise validated.error.exception(validated) if raise_error && validated.invalid?

      validated
    end

    private

    def resolve_path(rack_request)
      return rack_request.path unless @config.path

      @config.path.call(rack_request)
    end
  end
end
