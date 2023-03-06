require "sequel"
require "sequel/connection_pool/threaded"
require "yaml"
require "pact_broker/logging"
require "erb"
require "pact_broker/project_root"
require "fileutils"

module PactBroker
  module TestDatabase
    include PactBroker::Logging

    def self.connection_for_test_database
      @connection_for_test_database ||= connect(configuration_for_test_database)
    end

    def self.configuration_for_test_database
      @configuration_for_test_database ||= begin
                                        if ENV["PACT_BROKER_TEST_DATABASE_URL"] && ENV["PACT_BROKER_TEST_DATABASE_URL"] != ""
                                          uri = URI(ENV["PACT_BROKER_TEST_DATABASE_URL"])
                                          {
                                            "adapter" => uri.scheme,
                                            "user" => uri.user,
                                            "password" => uri.password,
                                            "host" => uri.host,
                                            "database" => uri.path.sub(/^\//, ""),
                                            "port" => uri.port&.to_i
                                          }.compact
                                        else
                                          configuration_for_env(ENV.fetch("RACK_ENV"))
                                        end
                                      end
    end

    def self.sqlite?
      !!(configuration_for_test_database["adapter"] =~ /sqlite/)
    end

    def self.mysql?
      !!(configuration_for_test_database["adapter"] =~ /mysql/)
    end

    def self.postgres?
      !!(configuration_for_test_database["adapter"] =~ /postgres/)
    end

    def self.connect(db_credentials)
      # Keep this conifiguration in sync with lib/pact_broker/app.rb#configure_database_connection
      Sequel.datetime_class = DateTime
      if ENV["DEBUG"] == "true"
        logger = PactBroker.logger
      end
      if db_credentials.fetch("adapter") == "sqlite"
        FileUtils.mkdir_p(File.dirname(db_credentials.fetch("database")))
      end
      PactBroker.logger.info "Connecting to #{db_credentials['adapter']} database #{db_credentials['database']}."
      con = Sequel.connect(db_credentials.merge(:logger => logger, :pool_class => Sequel::ThreadedConnectionPool, :encoding => "utf8", sql_log_level: ENV.fetch("PACT_BROKER_SQL_LOG_LEVEL", "trace")&.to_sym))
      con.extension(:connection_validator)
      con.extension(:pagination)
      con.extension(:statement_timeout)
      con.extension(:any_not_empty)
      #con.extension(:caller_logging)
      con.timezone = :utc
      con.run("SET sql_mode='STRICT_TRANS_TABLES';") if db_credentials[:adapter].to_s =~ /mysql/
      con
    end

    def self.configuration_for_env env
      database_yml = PactBroker.project_root.join("config","database.yml")
      yaml_load_opts = RUBY_VERSION.start_with?("2") ? {} : { aliases: true }
      config = YAML.load(ERB.new(File.read("config/database.yml")).result, **yaml_load_opts)
      config.fetch(env).fetch(ENV.fetch("DATABASE_ADAPTER","default"))
    end
  end
end
