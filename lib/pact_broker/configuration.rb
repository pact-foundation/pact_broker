module PactBroker

  class Configuration

    attr_accessor :log_dir, :database_connection, :auto_migrate_db, :use_hal_browser
    attr_writer :logger

    def logger
      @logger ||= create_logger log_path
    end

    def self.default_configuration
      config = Configuration.new
      config.log_dir = File.expand_path("./log")
      config.auto_migrate_db = true
      config.use_hal_browser = true
      config
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