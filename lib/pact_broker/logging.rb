require 'pathname'
require 'semantic_logger'

module PactBroker

  module Logging
    def self.included(base)
      base.extend(self)
    end

    def log_error e, description = nil
      message = "#{e.class} #{e.message} #{e.backtrace.join("\n")}"
      message = "#{description} - #{message}" if description
      logger.error message
    end
  end

  include Logging
end
