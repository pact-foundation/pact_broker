# frozen_string_literal: true

require_relative 'test/configuration'
require_relative 'test/registry'

module OpenapiFirst
  # Test integration
  module Test
    autoload :Coverage, 'openapi_first/test/coverage'
    autoload :Methods, 'openapi_first/test/methods'
    autoload :Callable, 'openapi_first/test/callable'
    autoload :Observe, 'openapi_first/test/observe'
    extend Registry

    class CoverageError < Error; end

    # Inject request/response validation in a rack app class
    def self.observe(app, api: :default)
      Observe.observe(app, api:)
    end

    def self.minitest?(base)
      base.include?(::Minitest::Assertions)
    rescue NameError
      false
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    # Sets up OpenAPI test coverage and OAD registration.
    # @yieldparam [OpenapiFirst::Test::Configuration] configuration A configuration to setup test integration
    def self.setup
      unless block_given?
        raise ArgumentError, "Please provide a block to #{self.class}.confgure to register you API descriptions"
      end

      install
      yield configuration

      configuration.registry.each { |name, oad| register(oad, as: name) }
      configuration.apps.each { |name, apps| apps.each { |app| observe(app, api: name) } }
      Coverage.start(skip_response: configuration.skip_response_coverage, skip_route: configuration.skip_coverage)

      if definitions.empty?
        raise NotRegisteredError,
              'No API descriptions have been registered. ' \
              'Please register your API description via ' \
              "OpenapiFirst::Test.setup { |test| test.register('myopenapi.yaml') }"
      end

      @exit_handler = method(:handle_exit)

      @setup ||= at_exit do
        # :nocov:
        @exit_handler&.call
        # :nocov:
      end
    end

    def self.handle_exit
      return unless configuration.report_coverage

      report_coverage(
        formatter: configuration.coverage_formatter,
        **configuration.coverage_formatter_options
      )
      return unless configuration.report_coverage == true

      coverage = Coverage.result.coverage
      return if coverage >= configuration.minimum_coverage

      puts "API Coverage fails with exit 2, because not all described requests and responses have been tested (#{coverage.round(4)}% covered)." # rubocop:disable Layout/LineLength

      exit 2
    end

    # Print the coverage report
    # @param formatter A formatter to define the report.
    # @output [IO] An output where to puts the report.
    def self.report_coverage(formatter: Coverage::TerminalFormatter, **)
      puts formatter.new(**).format(Coverage.result)
    end

    # Returns the Rack app wrapped with silent request, response validation
    # You can use this if you want to track coverage via Test::Coverage, but don't want to use
    # the middlewares or manual request, response validation.
    def self.app(app, spec: nil, api: :default)
      spec ||= self[api]
      Rack::Builder.app do
        use OpenapiFirst::Middlewares::ResponseValidation, spec:, raise_error: false
        use OpenapiFirst::Middlewares::RequestValidation, spec:, raise_error: false, error_response: false
        run app
      end
    end

    def self.install
      return if @installed

      OpenapiFirst.configure do |config|
        @after_request_validation = config.after_request_validation do |validated_request, oad|
          raise validated_request.error.exception if raise_request_error?(validated_request)

          Coverage.track_request(validated_request, oad)
        end

        @after_response_validation = config.after_response_validation do |validated_response, rack_request, oad|
          if validated_response.invalid? && raise_response_error?(validated_response)
            raise validated_response.error.exception
          end

          Coverage.track_response(validated_response, rack_request, oad)
        end
      end
      @installed = true
    end

    def self.raise_request_error?(validated_request)
      return false if validated_request.valid?
      return false if validated_request.known?

      !configuration.ignore_unknown_requests
    end

    def self.raise_response_error?(validated_response)
      configuration.response_raise_error && !configuration.ignored_unknown_status.include?(validated_response.status)
    end

    def self.uninstall
      configuration = OpenapiFirst.configuration
      configuration.hooks[:after_request_validation].delete(@after_request_validation)
      configuration.hooks[:after_response_validation].delete(@after_response_validation)
      definitions.clear
      @configuration = nil
      @installed = nil
      @exit_handler = nil
    end
  end
end
