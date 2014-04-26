require 'pact_broker/configuration'
require 'pact_broker/db'

module PactBroker

  class App

    attr_accessor :configuration

    def initialize &block
      @configuration = Configuration.default_configuration
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

      if configuration.auto_migrate_db
        logger.info "Migrating database"
        PactBroker::DB.run_migrations configuration.database_connection
      else
        logger.info "Skipping database migrations"
      end
    end

    def build_app
      @app = Rack::Builder.new

      if configuration.use_hal_browser
        logger.info "Mounting HAL browser"
        @app.use Rack::HalBrowser::Redirect, :exclude => ['/trace']
      else
        logger.info "Not mounting HAL browser"
      end

      logger.info "Mounting PactBroker::API"
      require 'pact_broker/api'
      @app.map "/" do
        run PactBroker::API
      end

    end
  end

end