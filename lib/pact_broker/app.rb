require 'pact_broker/configuration'
require 'pact_broker/db'
require 'pact_broker/project_root'
require 'rack/hal_browser'
require 'rack/pact_broker/convert_file_extension_to_accept_header'
require 'pact_broker/configuration/configure_basic_auth'

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
      PactBroker::DB.connection = configuration.database_connection
      PactBroker::DB.connection.timezone = :utc
      PactBroker::DB.validate_connection_config if configuration.validate_database_connection_config

      if configuration.auto_migrate_db
        logger.info "Migrating database"
        PactBroker::DB.run_migrations configuration.database_connection
      else
        logger.info "Skipping database migrations"
      end
    end

    def build_app
      @app = Rack::Builder.new

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
      apps << PactBroker::API

      cascade = Rack::Cascade.new(apps)
      app_with_basic_auth = PactBroker::Configuration::ConfigureBasicAuth.call(cascade, configuration)

      @app.map "/" do
        run app_with_basic_auth
      end
    end
  end
end
