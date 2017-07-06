module PactBroker

  def self.configuration
    @@configuration ||= Configuration.default_configuration
  end

  # @private, for testing only
  def self.reset_configuration
    @@configuration = Configuration.default_configuration
  end

  class Configuration

    SAVABLE_SETTING_NAMES = [:order_versions_by_date, :use_case_sensitive_resource_names]

    attr_accessor :log_dir, :database_connection, :auto_migrate_db, :use_hal_browser, :html_pact_renderer
    attr_accessor :validate_database_connection_config, :enable_diagnostic_endpoints, :version_parser
    attr_accessor :use_case_sensitive_resource_names, :order_versions_by_date
    attr_accessor :semver_formats
    attr_accessor :enable_badge_resources
    attr_writer :logger

    def initialize
      @before_resource_hook = ->(resource){}
      @after_resource_hook = ->(resource){}
      @authenticate_with_basic_auth = nil
      @authorize = nil
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
      config.enable_badge_resources = false # For security
      config.use_case_sensitive_resource_names = true
      config.html_pact_renderer = default_html_pact_render
      config.version_parser = PactBroker::Versions::ParseSemanticVersion
      # Not recommended to set this to true unless there is no way to
      # consistently extract an orderable object from the consumer application version number.
      config.order_versions_by_date = false
      config.semver_formats = ["%M.%m.%p%s%d","%M.%m", "%M"]
      config
    end

    def self.default_html_pact_render
      lambda { |pact|
        require 'pact_broker/api/renderers/html_pact_renderer'
        PactBroker::Api::Renderers::HtmlPactRenderer.call pact
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
