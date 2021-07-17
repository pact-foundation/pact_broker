# frozen_string_literal: true
require "semantic_logger"

module PactBroker
  module Logging

    def self.included(base)
      base.extend self
      base.extend SemanticLogger::Loggable::ClassMethods
      base.class_eval do
        # Returns [SemanticLogger::Logger] class level logger
        def self.logger
          require "pact_broker/configuration"
          @logger ||= PactBroker.configuration.custom_logger || SemanticLogger[self]
        end

        # Replace instance class level logger
        def self.logger=(logger)
          @logger = logger
        end

        # Returns [SemanticLogger::Logger] instance level logger
        def logger
          @logger ||= self.class.logger
        end

        # Replace instance level logger
        def logger=(logger)
          @logger = logger
        end
      end
    end

    def log_with_tag(tag)
      if logger.respond_to?(:tagged)
        logger.tagged(tag) do
          yield
        end
      else
        yield
      end
    end

    def log_error e, description = nil
      if logger.instance_of?(SemanticLogger::Logger)
        if description
          logger.error(description, e)
        else
          logger.error(e)
        end
      else
        message = "#{e.class} #{e.message}\n#{e.backtrace.join("\n")}"
        message = "#{description} - #{message}" if description
        logger.error message
      end
      if ENV["PACT_BROKER_HIDE_PACTFLOW_MESSAGES"] != "true"
        logger.info "\n\n#{'*' * 80}\n\nPrefer it was someone else's job to deal with this error? Check out https://pactflow.io/oss for a hardened, fully supported SaaS version of the Pact Broker with an improved UI  + more.\n\n#{'*' * 80}\n"
      end
    end
  end

  include Logging
end

# Hide the annoying warnings from Declarative gem. Need to upgrade Representable.
def Warning.warn(w)
  # super calls the original behavior, which is printing to $stderr
  super unless (w.start_with?("[Declarative] Defaults#merge!") || w.include?("URI.unescape is obsolete"))
end
