require "pact_broker/configuration"
# Stop Padrino creating a log file, as it will try to create it in the gems directory
# http://www.padrinorb.com/api/Padrino/Logger.html
unless defined? PADRINO_LOGGER
  log_path = File.join(PactBroker.configuration.log_dir, "ui.log")
  PADRINO_LOGGER = {
    production:  { log_level: :error, stream: :to_file, log_path: log_path },
    staging:     { log_level: :error, stream: :to_file, log_path: log_path },
    test:        { log_level: :warn,  stream: :to_file, log_path: log_path },
    development: { log_level: :warn,  stream: :to_file, log_path: log_path }
  }
end

require "pact_broker/ui/app"
