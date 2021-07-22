require "sequel"
require "pact_broker/db/log_quietener"
require "fileutils"

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

module PactBroker
  def self.create_database_connection(logger, config, max_retries = 0)
    logger&.info "Connecting to database with config: #{config.merge(password: "*****")}"
    config_with_logger =  if config[:sql_log_level] == :none
                            config.reject { |k, _| k == :sql_log_level }
                          else
                            config.merge(logger: PactBroker::DB::LogQuietener.new(logger))
                          end

    tries = 0
    max_tries = max_retries + 1
    connection = nil
    wait = 3

    if config[:adapter] == "sqlite" && config[:database] && !File.exist?(File.dirname(config[:database]))
      logger&.info "Creating directory #{File.expand_path(File.dirname(config[:database]))} for Sqlite database"
      FileUtils.mkdir_p(File.dirname(config[:database]))
    end

    begin
      connection = Sequel.connect(config_with_logger)
    rescue StandardError => e
      if (tries += 1) < max_tries
        logger&.info "Error connecting to database (#{e.class}). Waiting #{wait} seconds and trying again. #{max_tries-tries} tries to go."
        sleep wait
        retry
      else
        raise e
      end
    end
    logger&.info "Connected to database #{config[:database]}"
    connection.extension(:connection_validator)
    connection.pool.connection_validation_timeout = -1
    connection.timezone = config[:database_timezone]
    connection
  end
end
