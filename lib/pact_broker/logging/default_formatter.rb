require 'logger'
require 'semantic_logger'

module PactBroker
  module Logging
    class DefaultFormatter < SemanticLogger::Formatters::Default
      def initialize
        @formatter = ::Logger::Formatter.new
      end

      def call(log, output)
        @formatter.call(log.level.upcase, log.time, nil, log.message)
      end
    end
  end
end
