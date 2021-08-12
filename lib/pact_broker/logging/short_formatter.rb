require 'semantic_logger/formatters/default'

module PactBroker
  module Logging
    class ShortFormatter < SemanticLogger::Formatters::Default
      TAGS_TO_REMOVE = [:pact_broker_git_sha, :tenant_id, :request_id, :pactflow_git_sha]

      def call(log, logger)
        self.log    = log
        self.logger = logger

        [time, level, tags, named_tags, duration, message, payload, exception].compact.join(' ')
      end

      def time
        log.time.strftime("%H:%M:%S")
      end

      def named_tags
        named_tags = log.named_tags.reject{ | k, v | TAGS_TO_REMOVE.include?(k) }
        return if named_tags.nil? || named_tags.empty?

        list = []
        named_tags.each_pair { |name, value| list << "#{name}: #{value}" }
        "{#{list.join(', ')}}"
      end
    end
  end
end
