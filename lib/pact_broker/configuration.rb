module PactBroker

  def self.configuration
    @@configuration ||= Configuration.default_configuration
  end

  def self.reset_configuration
    @@configuration = Configuration.default_configuration
  end

  class Configuration

    REQUEST_METHOD = 'REQUEST_METHOD'.freeze
    GET = 'GET'.freeze
    PATH_INFO = 'PATH_INFO'.freeze
    DIAGNOSTIC = '/diagnostic/'.freeze

    attr_accessor :log_dir, :database_connection, :auto_migrate_db, :use_hal_browser, :html_pact_renderer
    attr_accessor :validate_database_connection_config, :enable_diagnostic_endpoints, :version_parser
    attr_accessor :use_case_sensitive_resource_names, :basic_auth_predicates
    attr_writer :logger

    def initialize
      @basic_auth_config = {}
      @basic_auth_predicates = [
        [:diagnostic,  ->(env) { env[PATH_INFO].start_with? DIAGNOSTIC }],
        [:app,         ->(env) { !env[PATH_INFO].start_with? DIAGNOSTIC } ],
        [:app_read,    ->(env) { env[REQUEST_METHOD] == GET }],
        [:app_write,   ->(env) { env[REQUEST_METHOD] != GET }],
        [:all,         ->(env) { true }]
      ]
    end

    def logger
      @logger ||= create_logger log_path
    end

    def self.default_configuration
      require 'pact_broker/versions/parse_semantic_version'
      config = Configuration.new
      config.log_dir = File.expand_path("./log")
      config.auto_migrate_db = true
      config.use_hal_browser = true
      config.validate_database_connection_config = true
      config.enable_diagnostic_endpoints = true
      config.use_case_sensitive_resource_names = true
      config.html_pact_renderer = default_html_pact_render
      config.version_parser = PactBroker::Versions::ParseSemanticVersion
      config
    end

    # public
    def self.default_html_pact_render
      lambda { |pact|
        require 'pact_broker/api/renderers/html_pact_renderer'
        PactBroker::Api::Renderers::HtmlPactRenderer.call pact
      }
    end

    # public
    def protect_with_basic_auth scopes, credentials
      [*scopes].each do | scope |
        basic_auth_config[scope] ||= []
        basic_auth_config[scope] << credentials
      end
    end

    # private
    def protect_with_basic_auth? scope
      !!basic_auth_credentials_list_for(scope)
    end

    # private
    def basic_auth_credentials_list_for scope
      basic_auth_config[scope]
    end

    private

    attr_reader :basic_auth_config

    def create_logger path
      FileUtils::mkdir_p File.dirname(path)
      logger = Logger.new(path)
      logger.level = Logger::DEBUG
      logger
    end

    def log_path
      log_dir + "/pact_broker.log"
    end

  end

end
