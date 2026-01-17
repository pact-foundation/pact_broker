require 'logger'

module Pact
  module MockService
    class Logger < ::Logger

      attr_reader :description

      def initialize stream
        super stream
        @description = if stream.is_a? File
           File.absolute_path(stream).gsub(Dir.pwd + "/", '')
        else
          "standard out/err"
        end
      end

      def self.from_options options
        log_stream = options[:log_file] || $stdout
        logger = new log_stream
        logger.formatter = options[:log_formatter] if options[:log_formatter]
        logger.level = logger_level(options[:log_level])
        logger
      end

      def self.logger_level log_level_string
        if log_level_string
          begin
            Kernel.const_get('Logger').const_get(log_level_string.upcase)
          rescue NameError
            $stderr.puts "WARN: Ignoring log level '#{log_level_string}' as it is not a valid value. Valid values are: DEBUG INFO WARN ERROR FATAL. Using DEBUG."
            Logger::DEBUG
          end
        else
          Logger::DEBUG
        end
      end
    end
  end
end
