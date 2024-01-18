require "padrino-core"
require "haml"
require "pact_broker/services"
require "pact_broker/string_refinements"

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

module PactBroker
  module UI
    module Controllers
      class Base < Padrino::Application
        using PactBroker::StringRefinements

        set :root, File.join(File.dirname(__FILE__), "..")
        set :show_exceptions, ENV["RACK_ENV"] == "development"
        # The padrino logger logs these for us, but only in production. If this is enabled we get duplicate logging.
        set :dump_errors, ENV["RACK_ENV"] != "production"
        set :raise_errors, ENV["RACK_ENV"] == "test"

        def base_url
          # Using the X-Forwarded headers in the UI can leave the app vulnerable
          # https://www.acunetix.com/blog/articles/automated-detection-of-host-header-attacks/
          # Either use the explicitly configured base url or an empty string,
          # rather than request.base_url, which uses the X-Forwarded headers.
          env["pactbroker.base_url"] || ""
        end

        helpers do
          def ellipsisize(string)
            string.ellipsisize
          end
        end
      end
    end
  end
end
