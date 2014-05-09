module PactBroker

  def self.configuration
    @@configuration ||= Configuration.default_configuration
  end

  class Configuration

    attr_accessor :log_dir, :database_connection, :auto_migrate_db, :use_hal_browser, :html_pact_renderer
    attr_writer :logger

    def logger
      @logger ||= create_logger log_path
    end

    def self.default_configuration
      config = Configuration.new
      config.log_dir = File.expand_path("./log")
      config.auto_migrate_db = true
      config.use_hal_browser = true
      config.html_pact_renderer = default_html_pact_render
      config
    end

    def self.default_html_pact_render
      lambda { |json_content|
        require 'pact_broker/api/renderers/html_pact_renderer'
        PactBroker::Api::Renderers::HtmlPactRenderer.call json_content
      }
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