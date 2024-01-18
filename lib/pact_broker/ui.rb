# Must be defined before loading Padrino
# Stop Padrino creating a log file, as it will try to create it in the gems directory
# http://www.padrinorb.com/api/Padrino/Logger.html
# This configuration will be replaced by the SemanticLogger later on.
PADRINO_LOGGER ||= {
  ENV.fetch("RACK_ENV", "production").to_sym =>  { stream: :stdout }
}

require "padrino-core"

class PactBrokerPadrinoLogger < SemanticLogger::Logger
  include Padrino::Logger::Extensions

  # Padrino expects level to return an integer, not a symbol
  def level
    Padrino::Logger::Levels[SemanticLogger.default_level]
  end
end

Padrino.logger = PactBrokerPadrinoLogger.new("Padrino")
# Log a test message to ensure that the logger works properly, as it only
# seems to be used in production.
Padrino.logger.info("Padrino has been configured with SemanticLogger")

require "pact_broker/ui/app"
