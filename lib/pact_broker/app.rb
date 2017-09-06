require 'pact_broker/configuration'
require 'pact_broker/db'
require 'pact_broker/project_root'
require 'rack-protection'
require 'rack/hal_browser'
require 'rack/pact_broker/add_pact_broker_version_header'
require 'rack/pact_broker/convert_file_extension_to_accept_header'
require 'rack/pact_broker/database_transaction'
require 'rack/pact_broker/invalid_uri_protection'
require 'rack/pact_broker/accepts_html_filter'
require 'rack/pact_broker/ui_authentication'
require 'sucker_punch'

module PactBroker

  class App

    attr_accessor :configuration

    def initialize &block
      @app_builder = ::Rack::Builder.new
      @cascade_apps = []
      @configuration = PactBroker.configuration
      yield configuration
      post_configure
      migrate_database
      prepare_app
    end

    def use *args, &block
      @app_builder.use *args, &block
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

    def migrate_database
      if configuration.auto_migrate_db
        logger.info "Migrating database"
        PactBroker::DB.run_migrations configuration.database_connection
      else
        logger.info "Skipping database migrations"
      end
    end

    def configure_database_connection
      PactBroker::DB.connection = configuration.database_connection
      PactBroker::DB.connection.timezone = :utc
      PactBroker::DB.validate_connection_config if configuration.validate_database_connection_config
      Sequel.datetime_class = DateTime
      Sequel.database_timezone = :utc # Store all dates in UTC, assume any date without a TZ is UTC
      Sequel.application_timezone = :local # Convert dates to localtime when retrieving from database
      Sequel.typecast_timezone = :utc # If no timezone specified on dates going into the database, assume they are UTC
    end

    def prepare_app
      configure_middleware

      if configuration.enable_diagnostic_endpoints
        @cascade_apps << build_diagnostic
      end

      @cascade_apps << build_ui
      @cascade_apps << build_api
    end

    def configure_middleware
      @app_builder.use Rack::Protection, except: [:remote_token, :session_hijacking, :http_origin]
      @app_builder.use Rack::PactBroker::InvalidUriProtection
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
      builder.use Rack::PactBroker::UIAuthentication
      builder.run PactBroker::UI::App.new
      builder
    end

    def build_api
      logger.info "Mounting PactBroker::API"
      require 'pact_broker/api'
      builder = ::Rack::Builder.new
      builder.use Rack::PactBroker::DatabaseTransaction, configuration.database_connection
      builder.run PactBroker::API
      builder
    end

    def build_diagnostic
      require 'pact_broker/diagnostic/app'
      builder = ::Rack::Builder.new
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
