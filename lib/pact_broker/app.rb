# Must be defined before loading Padrino
PADRINO_LOGGER ||= {
  ENV.fetch('RACK_ENV', 'production').to_sym =>  { log_level: :error, stream: :stdout, format_datetime: '%Y-%m-%dT%H:%M:%S.000%:z' }
}

require "pact_broker/configuration"
require "pact_broker/db"
require "pact_broker/initializers/database_connection"
require "pact_broker/project_root"
require "pact_broker/logging/default_formatter"
require "pact_broker/policies"
require "rack-protection"
require "rack/hal_browser"
require "rack/pact_broker/set_base_url"
require "rack/pact_broker/add_pact_broker_version_header"
require "rack/pact_broker/convert_file_extension_to_accept_header"
require "rack/pact_broker/database_transaction"
require "rack/pact_broker/invalid_uri_protection"
require "rack/pact_broker/ui_request_filter"
require "rack/pact_broker/ui_authentication"
require "rack/pact_broker/configurable_make_it_later"
require "rack/pact_broker/no_auth"
require "rack/pact_broker/convert_404_to_hal"
require "rack/pact_broker/reset_thread_data"
require "rack/pact_broker/add_vary_header"
require "rack/pact_broker/use_when"
require "sucker_punch"
require "pact_broker/api/middleware/basic_auth"
require "pact_broker/config/basic_auth_configuration"
require "pact_broker/api/authorization/resource_access_policy"

module PactBroker

  class App
    include PactBroker::Logging
    using Rack::PactBroker::UseWhen

    attr_accessor :configuration

    def initialize
      @app_builder = ::Rack::Builder.new
      @cascade_apps = []
      @make_it_later_api_auth = ::Rack::PactBroker::ConfigurableMakeItLater.new(Rack::PactBroker::NoAuth)
      @make_it_later_ui_auth = ::Rack::PactBroker::ConfigurableMakeItLater.new(Rack::PactBroker::NoAuth)
      # Can only be required after database connection has been made because the decorators rely on the Sequel models
      @create_pact_broker_api_block = ->() { require "pact_broker/api"; PactBroker::API }
      @configuration = PactBroker.configuration
      yield configuration
      post_configure
      prepare_database
      load_configuration_from_database
      seed_example_data
      print_startup_message
    end

    # Allows middleware to be inserted at the bottom of the shared middlware stack
    # (ie just before the cascade is called for diagnostic, UI and API).
    # To insert middleware at the top of the stack, initialize
    # the middleware with the app, and run it manually.
    # eg run MyMiddleware.new(app)
    def use *args, &block
      @app_builder.use(*args, &block)
    end

    # private API, not sure if this will continue to be supported
    def use_api_auth middleware
      @make_it_later_api_auth.make_it_later(middleware)
    end

    # private API, not sure if this will continue to be supported
    def use_ui_auth middleware
      @make_it_later_ui_auth.make_it_later(middleware)
    end

    def use_custom_ui custom_ui
      @custom_ui = custom_ui
    end

    def use_custom_api custom_api
      @custom_api = custom_api
    end

    def use_to_create_pact_broker_api &block
      @create_pact_broker_api_block = block
    end

    def call env
      running_app.call env
    end

    private

    attr_reader :custom_ui, :create_pact_broker_api_block

    def post_configure
      SuckerPunch.logger = configuration.custom_logger || SemanticLogger["SuckerPunch"]
      configure_database_connection
      configure_sucker_punch
    end

    def prepare_database
      logger.info "Database schema version is #{PactBroker::DB.version(configuration.database_connection)}"
      if configuration.auto_migrate_db
        migration_options = { allow_missing_migration_files: configuration.allow_missing_migration_files }
        if PactBroker::DB.is_current?(configuration.database_connection, migration_options)
          logger.info "Skipping database migrations as the latest migration has already been applied"
        else
          logger.info "Migrating database schema"
          PactBroker::DB.run_migrations configuration.database_connection, migration_options
          logger.info "Database schema version is now #{PactBroker::DB.version(configuration.database_connection)}"
        end
      else
        logger.info "Skipping database schema migrations as database auto migrate is disabled"
      end

      if configuration.auto_migrate_db_data
        logger.info "Migrating data"
        PactBroker::DB.run_data_migrations configuration.database_connection
      else
        logger.info "Skipping data migrations"
      end

      require "pact_broker/webhooks/service"
      PactBroker::Webhooks::Service.fail_retrying_triggered_webhooks
    end

    def load_configuration_from_database
      require "pact_broker/config/load"
      PactBroker::Config::Load.call(configuration)
    end

    def configure_database_connection
      # Keep this configuration in sync with lib/db.rb
      configuration.database_connection ||= PactBroker.create_database_connection(configuration.database_configuration, configuration.logger)
      PactBroker::DB.connection = configuration.database_connection
      PactBroker::DB.connection.extend_datasets do
        # rubocop: disable Lint/NestedMethodDefinition
        def any?
          !empty?
        end
        # rubocop: enable Lint/NestedMethodDefinition
      end
      PactBroker::DB.validate_connection_config if configuration.validate_database_connection_config
      PactBroker::DB.set_mysql_strict_mode_if_mysql
      PactBroker::DB.connection.extension(:pagination)
      PactBroker::DB.connection.extension(:statement_timeout)
      PactBroker::DB.connection.timezone = :utc
      Sequel.datetime_class = DateTime
      Sequel.database_timezone = :utc # Store all dates in UTC, assume any date without a TZ is UTC
      Sequel.application_timezone = :local # Convert dates to localtime when retrieving from database
      Sequel.typecast_timezone = :utc # If no timezone specified on dates going into the database, assume they are UTC
    end

    def seed_example_data
      if configuration.seed_example_data && configuration.example_data_seeder
        logger.info "Seeding example data"
        configuration.example_data_seeder.call
        logger.info "Marking seed as done"
        configuration.seed_example_data = false
        require "pact_broker/config/save"
        PactBroker::Config::Save.call(configuration, [:seed_example_data])
      else
        logger.info "Not seeding example data"
      end
    rescue StandardError => e
      logger.error "Error running example data seeder, #{e.class} #{e.message}", e
    end

    def prepare_app
      configure_middleware

      # need this first so UI login logic is performed before API login logic
      @cascade_apps << build_ui

      if configuration.enable_diagnostic_endpoints
        @cascade_apps << build_diagnostic
      end

      @cascade_apps << build_api
    end

    def configure_middleware
      configure_basic_auth
      configure_rack_protection
      @app_builder.use Rack::PactBroker::InvalidUriProtection
      @app_builder.use Rack::PactBroker::ResetThreadData
      @app_builder.use Rack::PactBroker::AddPactBrokerVersionHeader
      @app_builder.use Rack::PactBroker::AddVaryHeader
      @app_builder.use Rack::Static, :urls => ["/stylesheets", "/css", "/fonts", "/js", "/javascripts", "/images"], :root => PactBroker.project_root.join("public")
      @app_builder.use Rack::Static, :urls => ["/favicon.ico"], :root => PactBroker.project_root.join("public/images"), header_rules: [[:all, {"Content-Type" => "image/x-icon"}]]
      @app_builder.use Rack::PactBroker::ConvertFileExtensionToAcceptHeader
      # Rack::PactBroker::SetBaseUrl needs to be before the Rack::PactBroker::HalBrowserRedirect
      @app_builder.use Rack::PactBroker::SetBaseUrl, configuration.base_urls

      if configuration.use_hal_browser
        logger.info "Mounting HAL browser"
        @app_builder.use Rack::HalBrowser::Redirect
      else
        logger.info "Not mounting HAL browser"
      end
    end

    def configure_basic_auth
      if configuration.basic_auth_enabled
        logger.info "Configuring basic auth"
        logger.warn "No basic auth credentials are configured" unless configuration.basic_auth_credentials_provided?
        logger.info "Public read access is enabled" if configuration.allow_public_read
        policy = PactBroker::Api::Authorization::ResourceAccessPolicy
                  .build(
                    configuration.allow_public_read,
                    configuration.public_heartbeat,
                    configuration.enable_public_badge_access
                  )

        @app_builder.use PactBroker::Api::Middleware::BasicAuth,
          configuration.basic_auth_write_credentials,
          configuration.basic_auth_read_credentials,
          policy
      end
    end

    def configure_rack_protection
      if configuration.use_rack_protection
        @app_builder.use Rack::Protection, except: [:path_traversal, :remote_token, :session_hijacking, :http_origin]

        is_hal_browser = ->(env) { env["PATH_INFO"] == "/hal-browser/browser.html" }
        not_hal_browser = ->(env) { env["PATH_INFO"] != "/hal-browser/browser.html" }

        @app_builder.use_when not_hal_browser,
          Rack::Protection::ContentSecurityPolicy, configuration.content_security_policy
        @app_builder.use_when is_hal_browser,
          Rack::Protection::ContentSecurityPolicy,
          configuration.content_security_policy.merge(configuration.hal_browser_content_security_policy_overrides)
      end
    end

    def build_ui
      logger.info "Mounting UI"
      require "pact_broker/ui"
      ui_apps = [PactBroker::UI::App.new]
      ui_apps.unshift(@custom_ui) if @custom_ui
      builder = ::Rack::Builder.new
      builder.use Rack::PactBroker::UIRequestFilter
      builder.use @make_it_later_ui_auth
      builder.use Rack::PactBroker::UIAuthentication # deprecate?
      builder.run Rack::Cascade.new(ui_apps)
      builder
    end

    def build_api
      logger.info "Mounting PactBroker::API"
      api_apps = [create_pact_broker_api_block.call]
      api_apps.unshift(@custom_api) if @custom_api
      builder = ::Rack::Builder.new
      builder.use @make_it_later_api_auth
      builder.use Rack::PactBroker::Convert404ToHal
      builder.use Rack::PactBroker::DatabaseTransaction, configuration.database_connection
      builder.run Rack::Cascade.new(api_apps, [404])
      builder
    end

    def build_diagnostic
      require "pact_broker/diagnostic/app"
      builder = ::Rack::Builder.new
      builder.use @make_it_later_api_auth
      builder.run PactBroker::Diagnostic::App.new
      builder
    end

    def configure_sucker_punch
      SuckerPunch.exception_handler = -> (ex, klass, args) do
        PactBroker.logger.warn("Unhandled Suckerpunch error for #{klass}.perform(#{args.inspect})", ex)
      end
    end

    def running_app
      @running_app ||= begin
        prepare_app
        apps = @cascade_apps
        @app_builder.map "/" do
          run Rack::Cascade.new(apps, [404])
        end
        @app_builder
      end
    end

    def print_startup_message
      unless configuration.hide_pactflow_messages
        logger.info "\n\n#{'*' * 80}\n\nWant someone to manage your Pact Broker for you? Check out https://pactflow.io/oss for a hardened, fully supported SaaS version of the Pact Broker with an improved UI + more.\n\n#{'*' * 80}\n"
      end
    end
  end
end
