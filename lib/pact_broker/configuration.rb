require 'pact_broker/error'

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

    SAVABLE_SETTING_NAMES = [
      :order_versions_by_date,
      :use_case_sensitive_resource_names,
      :enable_public_badge_access,
      :shields_io_base_url,
      :check_for_potential_duplicate_pacticipant_names,
      :webhook_retry_schedule,
      :semver_formats,
      :disable_ssl_verification,
      :ignore_interaction_order
    ]

    attr_accessor :log_dir, :database_connection, :auto_migrate_db, :use_hal_browser, :html_pact_renderer
    attr_accessor :validate_database_connection_config, :enable_diagnostic_endpoints, :version_parser
    attr_accessor :use_case_sensitive_resource_names, :order_versions_by_date
    attr_accessor :check_for_potential_duplicate_pacticipant_names
    attr_accessor :semver_formats
    attr_accessor :enable_public_badge_access, :shields_io_base_url
    attr_accessor :webhook_retry_schedule
    attr_accessor :disable_ssl_verification
    attr_accessor :ignore_interaction_order
    attr_reader :api_error_reporters
    attr_writer :logger

    def initialize
      @before_resource_hook = ->(resource){}
      @after_resource_hook = ->(resource){}
      @authenticate_with_basic_auth = nil
      @authorize = nil
      @api_error_reporters = []
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
      config.enable_public_badge_access = false # For security
      config.shields_io_base_url = "https://img.shields.io".freeze
      config.use_case_sensitive_resource_names = true
      config.html_pact_renderer = default_html_pact_render
      config.version_parser = PactBroker::Versions::ParseSemanticVersion
      # Not recommended to set this to true unless there is no way to
      # consistently extract an orderable object from the consumer application version number.
      config.order_versions_by_date = false
      config.semver_formats = ["%M.%m.%p%s%d", "%M.%m", "%M"]
      config.webhook_retry_schedule = [10, 60, 120, 300, 600, 1200] #10 sec, 1 min, 2 min, 5 min, 10 min, 20 min => 38 minutes
      config.check_for_potential_duplicate_pacticipant_names = true
      config.disable_ssl_verification = false
      config.ignore_interaction_order = true
      config
    end

    def self.default_html_pact_render
      lambda { |pact, options|
        require 'pact_broker/api/renderers/html_pact_renderer'
        PactBroker::Api::Renderers::HtmlPactRenderer.call pact, options
      }
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

    def enable_badge_resources= enable_badge_resources
      puts "Pact Broker configuration property `enable_badge_resources` is deprecated. Please use `enable_public_badge_access`"
      self.enable_public_badge_access = enable_badge_resources
    end

    def base_url
      ENV['PACT_BROKER_BASE_URL']
    end

    def save_to_database
      # Can't require a Sequel::Model class before the connection has been set
      require 'pact_broker/config/save'
      PactBroker::Config::Save.call(self, SAVABLE_SETTING_NAMES)
    end

    def load_from_database!
      # Can't require a Sequel::Model class before the connection has been set
      require 'pact_broker/config/load'
      PactBroker::Config::Load.call(self)
    end

    private

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
