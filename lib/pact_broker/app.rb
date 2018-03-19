require 'pact_broker/configuration'
require 'pact_broker/db'
require 'pact_broker/project_root'
require 'rack-protection'
require 'rack/hal_browser'
require 'rack/pact_broker/store_base_url'
require 'rack/pact_broker/add_pact_broker_version_header'
require 'rack/pact_broker/convert_file_extension_to_accept_header'
require 'rack/pact_broker/database_transaction'
require 'rack/pact_broker/invalid_uri_protection'
require 'rack/pact_broker/accepts_html_filter'
require 'rack/pact_broker/ui_authentication'
require 'rack/pact_broker/configurable_make_it_later'
require 'rack/pact_broker/no_auth'
require 'semver/dsl'
require 'semver/pre_release'
require 'semver/runner'
require 'semver/semver'
require 'semver/semvermissingerror'
require 'semver/xsemver'
require 'sucker_punch'

module PactBroker

  class App

    attr_accessor :configuration

    def initialize &block
      @app_builder = ::Rack::Builder.new
      @cascade_apps = []
      @make_it_later_api_auth = ::Rack::PactBroker::ConfigurableMakeItLater.new(Rack::PactBroker::NoAuth)
      @make_it_later_ui_auth = ::Rack::PactBroker::ConfigurableMakeItLater.new(Rack::PactBroker::NoAuth)
      @configuration = PactBroker.configuration
      yield configuration
      post_configure
      prepare_database
      prepare_app
    end

    # Allows middleware to be inserted at the bottom of the shared middlware stack
    # (ie just before the cascade is called for diagnostic, UI and API).
    # To insert middleware at the top of the stack, initialize
    # the middleware with the app, and run it manually.
    # eg run MyMiddleware.new(app)
    def use *args, &block
      @app_builder.use *args, &block
    end

    # private API, not sure if this will continue to be supported
    def use_api_auth middleware
      @make_it_later_api_auth.make_it_later(middleware)
    end

    # private API, not sure if this will continue to be supported
    def use_ui_auth middleware
      @make_it_later_ui_auth.make_it_later(middleware)
    end

    def call env
      running_app.call env
    end

    private

    def logger
      PactBroker.logger
    end

    def post_configure
      PactBroker.logger = configuration.logger
      SuckerPunch.logger = configuration.logger
      configure_database_connection
      configure_sucker_punch
    end

    def prepare_database
      if configuration.auto_migrate_db
        logger.info "Migrating database"
        PactBroker::DB.run_migrations configuration.database_connection
      else
        logger.info "Skipping database migrations"
      end
      require 'pact_broker/webhooks/service'
      PactBroker::Webhooks::Service.fail_retrying_triggered_webhooks
    end

    def configure_database_connection
      PactBroker::DB.connection = configuration.database_connection
      PactBroker::DB.connection.timezone = :utc
      PactBroker::DB.validate_connection_config if configuration.validate_database_connection_config
      PactBroker::DB.set_mysql_strict_mode_if_mysql
      Sequel.datetime_class = DateTime
      Sequel.database_timezone = :utc # Store all dates in UTC, assume any date without a TZ is UTC
      Sequel.application_timezone = :local # Convert dates to localtime when retrieving from database
      Sequel.typecast_timezone = :utc # If no timezone specified on dates going into the database, assume they are UTC
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
      # NOTE THAT NONE OF THIS IS PROTECTED BY AUTH - is that ok?
      @app_builder.use Rack::Protection, except: [:path_traversal, :remote_token, :session_hijacking, :http_origin]
      @app_builder.use Rack::PactBroker::InvalidUriProtection
      @app_builder.use Rack::PactBroker::StoreBaseURL
      @app_builder.use Rack::PactBroker::AddPactBrokerVersionHeader
      @app_builder.use Rack::Static, :urls => ["/stylesheets", "/css", "/fonts", "/js", "/javascripts", "/images"], :root => PactBroker.project_root.join("public")
      @app_builder.use Rack::Static, :urls => ["/favicon.ico"], :root => PactBroker.project_root.join("public/images"), header_rules: [[:all, {'Content-Type' => 'image/x-icon'}]]
      @app_builder.use Rack::PactBroker::ConvertFileExtensionToAcceptHeader

      if configuration.use_hal_browser
        logger.info "Mounting HAL browser"
        @app_builder.use Rack::HalBrowser::Redirect
      else
        logger.info "Not mounting HAL browser"
      end
    end

    def build_ui
      logger.info "Mounting UI"
      require 'pact_broker/ui'
      builder = ::Rack::Builder.new
      builder.use Rack::PactBroker::AcceptsHtmlFilter
      builder.use @make_it_later_ui_auth
      builder.use Rack::PactBroker::UIAuthentication # deprecate?
      builder.run PactBroker::UI::App.new
      builder
    end

    def build_api
      logger.info "Mounting PactBroker::API"
      require 'pact_broker/api'
      builder = ::Rack::Builder.new
      builder.use @make_it_later_api_auth
      builder.use Rack::PactBroker::DatabaseTransaction, configuration.database_connection
      builder.run PactBroker::API
      builder
    end

    def build_diagnostic
      require 'pact_broker/diagnostic/app'
      builder = ::Rack::Builder.new
      builder.use @make_it_later_api_auth
      builder.run PactBroker::Diagnostic::App.new
      builder
    end

    def configure_sucker_punch
      SuckerPunch.exception_handler = -> (ex, klass, args) do
        PactBroker.log_error(ex, "Unhandled Suckerpunch error for #{klass}.perform(#{args.inspect})")
      end
    end

    def running_app
      @running_app ||= begin
        apps = @cascade_apps
        @app_builder.map "/" do
          run Rack::Cascade.new(apps)
        end
        @app_builder
      end
    end
  end
end
