
# Stop Padrino creating a log file, as it will try to create it in the gems directory
# http://www.padrinorb.com/api/Padrino/Logger.html
unless defined? PADRINO_LOGGER
  PADRINO_LOGGER = {
    production:  { log_level: :error, stream: :stderr },
    staging:     { log_level: :error, stream: :stderr },
    test:        { log_level: :warn,  stream: :stdout },
    development: { log_level: :warn,  stream: :stdout }
  }
end

require 'pact_broker/ui/controllers/relationships'
require 'pact_broker/ui/controllers/groups'
