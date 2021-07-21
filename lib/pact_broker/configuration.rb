require "pact_broker/version"
require "pact_broker/error"
require "semantic_logger"
require "forwardable"
require "pact_broker/config/runtime_configuration"

module PactBroker
  class ConfigurationError < PactBroker::Error; end

  def self.configuration
    @@configuration ||= Configuration.default_configuration
  end

  # @private, for testing only
  def self.reset_configuration
    @@configuration = Configuration.default_configuration
  end

  class Configuration
    extend Forwardable

    delegate PactBroker::Config::RuntimeConfiguration.getter_and_setter_method_names => :runtime_configuration

    SAVABLE_SETTING_NAMES = [
      :order_versions_by_date,
      :use_case_sensitive_resource_names,
      :enable_public_badge_access,
      :shields_io_base_url,
      :check_for_potential_duplicate_pacticipant_names,
      :webhook_retry_schedule,
      :semver_formats,
      :disable_ssl_verification,
      :webhook_http_method_whitelist,
      :webhook_scheme_whitelist,
      :webhook_host_whitelist,
      :webhook_http_code_success,
      :base_equality_only_on_content_that_affects_verification_results,
      :seed_example_data,
      :badge_provider_mode,
      :warning_error_class_names,
      :base_urls,
      :log_dir,
      :allow_missing_migration_files,
      :auto_migrate_db_data,
      :use_rack_protection,
      :create_deployed_versions_for_tags,
      :metrics_sql_statement_timeout
    ]

    attr_accessor :database_connection
    attr_accessor :example_data_seeder, :seed_example_data
    attr_accessor :html_pact_renderer, :version_parser, :sha_generator
    attr_accessor :content_security_policy, :hal_browser_content_security_policy_overrides
    attr_accessor :api_error_reporters
    attr_reader :custom_logger
    attr_accessor :policy_builder, :policy_scope_builder, :base_resource_class_factory
    alias_method :policy_finder=, :policy_builder=
    alias_method :policy_scope_finder=, :policy_scope_builder=

    attr_accessor :runtime_configuration

    def initialize
      @runtime_configuration = PactBroker::Config::RuntimeConfiguration.new
      @before_resource_hook = ->(resource){}
      @after_resource_hook = ->(resource){}
      @authenticate_with_basic_auth = nil
      @authorize = nil
      @api_error_reporters = []
    end

    # rubocop: disable Metrics/MethodLength
    def self.default_configuration
      require "pact_broker/versions/parse_semantic_version"
      require "pact_broker/pacts/generate_sha"

      config = Configuration.new
      config.html_pact_renderer = default_html_pact_render
      config.version_parser = PactBroker::Versions::ParseSemanticVersion
      config.sha_generator = PactBroker::Pacts::GenerateSha
      config.seed_example_data = true
      config.example_data_seeder = lambda do
        require "pact_broker/db/seed_example_data"
        PactBroker::DB::SeedExampleData.call
      end

      # TODO get rid of unsafe-inline
      config.content_security_policy = {
        script_src: "'self' 'unsafe-inline'",
        style_src: "'self' 'unsafe-inline'",
        img_src: "'self' data: #{URI(config.shields_io_base_url).host}",
        font_src: "'self' data:",
        base_uri: "'self'",
        frame_src: "'self'",
        frame_ancestors: "'self'"
      }
      config.hal_browser_content_security_policy_overrides = {
        script_src: "'self' 'unsafe-inline' 'unsafe-eval'",
        frame_ancestors: "'self'"
      }
      config.policy_builder = -> (object) { DefaultPolicy.new(nil, object) }
      config.policy_scope_builder = -> (scope) { scope }
      config.base_resource_class_factory = -> () {
        require "pact_broker/api/resources/default_base_resource"
        PactBroker::Api::Resources::DefaultBaseResource
      }
      config
    end
    # rubocop: enable Metrics/MethodLength

    def logger_from_runtime_configuration
      @logger_from_runtime_configuration ||= begin
        SemanticLogger.default_level = runtime_configuration.log_level
        if runtime_configuration.log_dir
          path = runtime_configuration.log_dir + "/pact_broker.log"
          FileUtils.mkdir_p(runtime_configuration.log_dir)
          @default_appender = SemanticLogger.add_appender(file_name: path, formatter: runtime_configuration.log_format)
        else
          @default_appender = SemanticLogger.add_appender(io: $stdout, formatter: runtime_configuration.log_format)
        end
        @logger_from_runtime_configuration = SemanticLogger["pact-broker"]
      end
    end

    def logger
      custom_logger || logger_from_runtime_configuration
    end

    def logger= logger
      if @default_appender && SemanticLogger.appenders.include?(@default_appender)
        SemanticLogger.remove_appender(@default_appender)
        @default_appender = nil
      end
      @custom_logger = logger
    end

    def log_configuration
      runtime_configuration.log_configuration(logger)
    end

    def self.default_html_pact_render
      lambda { |pact, options|
        require "pact_broker/api/renderers/html_pact_renderer"
        PactBroker::Api::Renderers::HtmlPactRenderer.call pact, options
      }
    end

    def show_backtrace_in_error_response?
      !!(ENV["RACK_ENV"] && ENV["RACK_ENV"].downcase != "production")
    end

    def authentication_configured?
      !!authenticate || !!authenticate_with_basic_auth
    end

    def authenticate &block
      if block_given?
        @authenticate = block
      else
        @authenticate
      end
    end

    def authenticate_with_basic_auth &block
      if block_given?
        @authenticate_with_basic_auth = block
      else
        @authenticate_with_basic_auth
      end
    end

    def authorization_configured?
      !!authorize
    end

    def authorize &block
      if block_given?
        @authorize = block
      else
        @authorize
      end
    end

    def before_resource &block
      if block_given?
        @before_resource_hook = block
      else
        @before_resource_hook
      end
    end

    def after_resource &block
      if block_given?
        @after_resource_hook = block
      else
        @after_resource_hook
      end
    end

    def add_api_error_reporter &block
      if block_given?
        unless block.arity == 2
          raise ConfigurationError.new("api_error_notfifier block must accept two arguments, 'error' and 'options'")
        end
        @api_error_reporters << block
        nil
      end
    end

    def show_webhook_response?
      webhook_host_whitelist.any?
    end

    def enable_badge_resources= enable_badge_resources
      puts "Pact Broker configuration property `enable_badge_resources` is deprecated. Please use `enable_public_badge_access`"
      self.enable_public_badge_access = enable_badge_resources
    end

    def save_to_database
      # Can't require a Sequel::Model class before the connection has been set
      require "pact_broker/config/save"
      PactBroker::Config::Save.call(self, SAVABLE_SETTING_NAMES)
    end

    def load_from_database!
      # Can't require a Sequel::Model class before the connection has been set
      require "pact_broker/config/load"
      PactBroker::Config::Load.call(self)
    end
  end
end
