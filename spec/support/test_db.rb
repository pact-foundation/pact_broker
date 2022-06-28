require "sequel"
require "sequel/connection_pool/threaded"
require "yaml"
require "pact_broker/logging"
require "erb"
require "pact_broker/project_root"
require "fileutils"

module TestDB
  include PactBroker::Logging

  def self.connect(db_credentials)
    # Keep this conifiguration in sync with lib/pact_broker/app.rb#configure_database_connection
    Sequel.datetime_class = DateTime
    if ENV["DEBUG"] == "true" && ENV["PACT_BROKER_SQL_LOG_LEVEL"] && ENV["PACT_BROKER_SQL_LOG_LEVEL"] != "none"
      logger = Logger.new($stdout)
    end
    if db_credentials.fetch("adapter") == "sqlite"
      FileUtils.mkdir_p(File.dirname(db_credentials.fetch("database")))
    end
    con = Sequel.connect(db_credentials.merge(:logger => logger, :pool_class => Sequel::ThreadedConnectionPool, :encoding => "utf8"))
    con.extension(:connection_validator)
    con.extension(:pagination)
    con.extension(:statement_timeout)
    con.extension(:any_not_empty)
    #con.extension(:caller_logging)
    con.timezone = :utc
    con.run("SET sql_mode='STRICT_TRANS_TABLES';") if db_credentials[:adapter].to_s =~ /mysql/
    con
  end

  def self.connection_for_env env
    config = configuration_for_env(env)
    logger.info "Connecting to #{env} #{config['adapter']} database #{config['database']}."
    connect(config)
  end

  def self.configuration_for_env env
    database_yml = PactBroker.project_root.join("config","database.yml")
    config = YAML.load(ERB.new(File.read(database_yml)).result)
    config.fetch(env).fetch(ENV.fetch("DATABASE_ADAPTER","default"))
  end

  def self.sqlite?
    !!(test_database_configuration["adapter"] =~ /sqlite/)
  end

  def self.mysql?
    !!(test_database_configuration["adapter"] =~ /mysql/)
  end

  def self.postgres?
    !!(test_database_configuration["adapter"] =~ /postgres/)
  end

  def self.connection_for_test_database
    @connection_for_test_database ||= connect(test_database_configuration)
  end

  def self.test_database_configuration
    @test_database_configuration ||= begin
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
end
