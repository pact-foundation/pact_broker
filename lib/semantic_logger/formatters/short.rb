require "semantic_logger/formatters/default"

module SemanticLogger
  module Formatters
    # A compact, human readable formatter for local development.
    #
    # Named tags that are useful in aggregated production logs but only noise on
    # a developer's terminal are hidden. Consumers that add their own tags can
    # append to hidden_named_tags rather than this list naming concepts that do
    # not belong to the Pact Broker.
    class Short < SemanticLogger::Formatters::Default
      DEFAULT_HIDDEN_NAMED_TAGS = [:pact_broker_git_sha, :request_id].freeze

      class << self
        def hidden_named_tags=(value)
          @hidden_named_tags = Array(value)
        end

        def hidden_named_tags
          @hidden_named_tags ||= DEFAULT_HIDDEN_NAMED_TAGS.dup
        end
      end

      def call(log, logger)
        self.log    = log
        self.logger = logger

        [time, level, tags, named_tags, duration, message, payload, exception].compact.join(" ")
      end

      def time
        log.time.strftime("%H:%M:%S")
      end

      def named_tags
        visible_tags = (log.named_tags || {}).reject { | key, _ | self.class.hidden_named_tags.include?(key) }
        return if visible_tags.empty?

        list = []
        visible_tags.each_pair { |name, value| list << "#{name}: #{value}" }
        "{#{list.join(', ')}}"
      end
    end
  end
end
