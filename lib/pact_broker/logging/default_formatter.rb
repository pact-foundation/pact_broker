require 'logger'
require 'semantic_logger'

module PactBroker
  module Logging
    class DefaultFormatter < SemanticLogger::Formatters::Default
      def initialize
        @formatter = ::Logger::Formatter.new
      end

      def call(log, _output)
        self.log    = log
        self.logger = logger
        @formatter.call(log.level.upcase, log.time, nil, [tags, named_tags, duration, message, payload, exception].compact.join(" "))
      end
    end
  end
end
