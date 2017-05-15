require 'pact_broker/configuration'
require 'pact_broker/db'
require 'pact_broker/project_root'
require 'rack/hal_browser'
require 'rack/pact_broker/add_pact_broker_version_header'
require 'rack/pact_broker/convert_file_extension_to_accept_header'
require 'rack/pact_broker/database_transaction'
require 'sucker_punch'

module PactBroker

  class App

    attr_accessor :configuration

    def initialize &block
      @configuration = PactBroker.configuration
      yield configuration
      post_configure
      build_app
    end

    def call env
      @app.call env
    end

    private

    def logger
      PactBroker.logger
    end

    def post_configure
      PactBroker.logger = configuration.logger
      SuckerPunch.logger = configuration.logger
      configure_database_connection

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
      Sequel.database_timezone = :utc # Store all dates in UTC, assume any date without a TZ is UTC
      Sequel.application_timezone = :local # Convert dates to localtime when retrieving from database
      Sequel.typecast_timezone = :utc # If no timezone specified on dates going into the database, assume they are UTC
    end

    def build_app
      @app = Rack::Builder.new

      @app.use Rack::PactBroker::AddPactBrokerVersionHeader
      @app.use Rack::Static, :urls => ["/stylesheets", "/css", "/fonts", "/js", "/javascripts", "/images"], :root => PactBroker.project_root.join("public")
      @app.use Rack::PactBroker::ConvertFileExtensionToAcceptHeader

      if configuration.use_hal_browser
        logger.info "Mounting HAL browser"
        @app.use Rack::HalBrowser::Redirect
      else
        logger.info "Not mounting HAL browser"
      end

      logger.info "Mounting UI"
      require 'pact_broker/ui'

      logger.info "Mounting PactBroker::API"
      require 'pact_broker/api'

      apps = []

      if configuration.enable_diagnostic_endpoints
        require 'pact_broker/diagnostic/app'
        apps << PactBroker::Diagnostic::App.new
      end

      apps << PactBroker::UI::App.new
      apps << Rack::PactBroker::DatabaseTransaction.new(PactBroker::API, configuration.database_connection)

      @app.map "/" do
        run Rack::Cascade.new(apps)
      end

    end

  end

end