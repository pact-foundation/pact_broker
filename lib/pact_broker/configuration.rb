require 'pact_broker/error'
require 'pact_broker/config/space_delimited_string_list'
require 'semantic_logger'

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
      :webhook_http_method_whitelist,
      :webhook_scheme_whitelist,
      :webhook_host_whitelist,
      :base_equality_only_on_content_that_affects_verification_results,
      :seed_example_data
    ]

    attr_accessor :base_url, :log_dir, :database_connection, :auto_migrate_db, :auto_migrate_db_data, :example_data_seeder, :seed_example_data, :use_hal_browser, :html_pact_renderer, :use_rack_protection
    attr_accessor :validate_database_connection_config, :enable_diagnostic_endpoints, :version_parser, :sha_generator
    attr_accessor :use_case_sensitive_resource_names, :order_versions_by_date
    attr_accessor :check_for_potential_duplicate_pacticipant_names
    attr_accessor :webhook_retry_schedule
    attr_reader :webhook_http_method_whitelist, :webhook_scheme_whitelist, :webhook_host_whitelist
    attr_accessor :semver_formats
    attr_accessor :enable_public_badge_access, :shields_io_base_url
    attr_accessor :disable_ssl_verification
    attr_accessor :base_equality_only_on_content_that_affects_verification_results
    attr_reader :api_error_reporters
    attr_reader :custom_logger

    def initialize
      @before_resource_hook = ->(resource){}
      @after_resource_hook = ->(resource){}
      @authenticate_with_basic_auth = nil
      @authorize = nil
      @api_error_reporters = []
      @semantic_logger = SemanticLogger["root"]
    end

    def self.default_configuration
      require 'pact_broker/versions/parse_semantic_version'
      require 'pact_broker/pacts/generate_sha'

      config = Configuration.new
      config.log_dir = File.expand_path("./log")
      config.auto_migrate_db = true
      config.auto_migrate_db_data = true
      config.use_rack_protection = true
      config.use_hal_browser = true
      config.validate_database_connection_config = true
      config.enable_diagnostic_endpoints = true
      config.enable_public_badge_access = false # For security
      config.shields_io_base_url = "https://img.shields.io".freeze
      config.use_case_sensitive_resource_names = true
      config.html_pact_renderer = default_html_pact_render
      config.version_parser = PactBroker::Versions::ParseSemanticVersion
      config.sha_generator = PactBroker::Pacts::GenerateSha
      config.seed_example_data = true
      config.example_data_seeder = lambda do
        require 'pact_broker/db/seed_example_data'
        PactBroker::DB::SeedExampleData.call
      end
      config.base_equality_only_on_content_that_affects_verification_results = true
      config.order_versions_by_date = true
      config.semver_formats = ["%M.%m.%p%s%d", "%M.%m", "%M"]
      config.webhook_retry_schedule = [10, 60, 120, 300, 600, 1200] #10 sec, 1 min, 2 min, 5 min, 10 min, 20 min => 38 minutes
      config.check_for_potential_duplicate_pacticipant_names = true
      config.disable_ssl_verification = false
      config.webhook_http_method_whitelist = ['POST']
      config.webhook_scheme_whitelist = ['https']
      config.webhook_host_whitelist = []
      config
    end

    def logger
      custom_logger || @semantic_logger
    end

    def logger= logger
      @custom_logger = logger
    end

    def self.default_html_pact_render
      lambda { |pact, options|
        require 'pact_broker/api/renderers/html_pact_renderer'
        PactBroker::Api::Renderers::HtmlPactRenderer.call pact, options
      }
    end

    def show_backtrace_in_error_response?
      !!(ENV['RACK_ENV'] && ENV['RACK_ENV'].downcase != 'production')
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
      require 'pact_broker/config/save'
      PactBroker::Config::Save.call(self, SAVABLE_SETTING_NAMES)
    end

    def load_from_database!
      # Can't require a Sequel::Model class before the connection has been set
      require 'pact_broker/config/load'
      PactBroker::Config::Load.call(self)
    end

    def webhook_http_method_whitelist= webhook_http_method_whitelist
      @webhook_http_method_whitelist = parse_space_delimited_string_list_property('webhook_http_method_whitelist', webhook_http_method_whitelist)
    end

    def webhook_scheme_whitelist= webhook_scheme_whitelist
      @webhook_scheme_whitelist = parse_space_delimited_string_list_property('webhook_scheme_whitelist', webhook_scheme_whitelist)
    end

    def webhook_host_whitelist= webhook_host_whitelist
      @webhook_host_whitelist = parse_space_delimited_string_list_property('webhook_host_whitelist', webhook_host_whitelist)
    end

    private

    def parse_space_delimited_string_list_property property_name, property_value
      case property_value
      when String then Config::SpaceDelimitedStringList.parse(property_value)
      when Array then Config::SpaceDelimitedStringList.new(property_value)
      else
        raise ConfigurationError.new("Pact Broker configuration property `#{property_name}` must be a space delimited String or an Array")
      end
    end
  end
end
