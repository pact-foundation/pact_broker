require "sequel"
require "pact_broker/db/log_quietener"
require "fileutils"

module PactBroker
  def self.create_database_connection(config, logger = nil)
    logger&.info "Connecting to database:", payload: "#{config.merge(password: "*****")}"

    sequel_config = config.dup
    max_retries = sequel_config.delete(:connect_max_retries) || 0
    timezone = config.delete(:timezone)
    connection_validation_timeout = config.delete(:connection_validation_timeout)
    configure_logger(sequel_config)
    create_sqlite_database_dir(config)

    connection = with_retries(max_retries, logger) do
      Sequel.connect(sequel_config)
    end

    logger&.info "Connected to database #{sequel_config[:database]}"

    configure_connection(connection, timezone, connection_validation_timeout)
  end

  private_class_method def self.with_retries(max_retries, logger)
    tries = 0
    max_tries = max_retries + 1
    wait = 3

    begin
      yield
    rescue StandardError => e
      if (tries += 1) < max_tries
        logger&.info "Error connecting to database (#{e.class}). Waiting #{wait} seconds and trying again. #{max_tries-tries} tries to go."
        sleep wait
        retry
      else
        raise e
      end
    end
  end
   :with_retries

  private_class_method def self.create_sqlite_database_dir(config)
    if config[:adapter] == "sqlite" && config[:database] && !File.exist?(File.dirname(config[:database]))
      logger&.info "Creating directory #{File.expand_path(File.dirname(config[:database]))} for Sqlite database"
      FileUtils.mkdir_p(File.dirname(config[:database]))
    end
  end

  private_class_method def self.configure_logger(sequel_config)
    if sequel_config[:sql_log_level] == :none
      sequel_config.delete(:sql_log_level)
    elsif logger
      sequel_config[:logger] = PactBroker::DB::LogQuietener.new(logger)
    end
  end

  ##
  # Sequel by default does not test connections in its connection pool before
  # handing them to a client. To enable connection testing you need to load the
  # "connection_validator" extension like below. The connection validator
  # extension is configurable, by default it only checks connections once per
  # hour:
  #
  # http://sequel.rubyforge.org/rdoc-plugins/files/lib/sequel/extensions/connection_validator_rb.html
  #
  #
  # A gotcha here is that it is not enough to enable the "connection_validator"
  # extension, we also need to specify that we want to use the threaded connection
  # pool, as noted in the documentation for the extension.
  #
  # -1 means that connections will be validated every time, which avoids errors
  # when databases are restarted and connections are killed.  This has a performance
  # penalty, so consider increasing this timeout if building a frequently accessed service.

  private_class_method def self.configure_connection(connection, timezone, connection_validation_timeout)
    connection.extension(:connection_validator)
    connection.pool.connection_validation_timeout = connection_validation_timeout if connection_validation_timeout
    connection
  end
end
