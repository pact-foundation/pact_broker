require 'logger'
require 'pathname'

module PactBroker

  module Logging

    # Need to make this configurable based on the calling app!
    LOG_DIR = Pathname.new(File.join(File.dirname(__FILE__), '..', '..', 'log')).cleanpath
    LOG_FILE_NAME = "#{ENV['RACK_ENV'] || 'development'}.log"

    def self.included(base)
      base.extend(self)
    end

    def logger= logger
      @@logger = logger
    end

    def logger
      @@logger ||= begin
        FileUtils.mkdir_p(LOG_DIR)
        logger = Logger.new(File.join(LOG_DIR, LOG_FILE_NAME))
        logger.level = Logger::DEBUG
        def logger.log_error e
          error "#{e.class} #{e.message} #{e.backtrace.join("\n")}"
        end
        logger
      end
    end
  end

  include Logging
end
