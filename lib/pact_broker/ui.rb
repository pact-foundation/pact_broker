# Must be defined before loading Padrino
# Stop Padrino creating a log file, as it will try to create it in the gems directory
# http://www.padrinorb.com/api/Padrino/Logger.html
# This configuration will be replaced by the SemanticLogger later on.
PADRINO_LOGGER ||= {
  ENV.fetch("RACK_ENV", "production").to_sym =>  { stream: :stdout }
}

require "pact_broker/ui/app"
