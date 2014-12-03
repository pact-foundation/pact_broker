
# Stop Padrino creating a log file, as it will try to create it in the gems directory
# http://www.padrinorb.com/api/Padrino/Logger.html
unless defined? PADRINO_LOGGER
  PADRINO_LOGGER = { production: { log_level: :warn, stream: :null } }
end

require 'pact_broker/ui/controllers/relationships'
require 'pact_broker/ui/controllers/groups'
