module PactBroker
  module Pacts
    module Interactions
      # Classifies the interactions of a pact as messages or HTTP, independent of spec version.
      class Types
        # Pact Spec v4+ message interaction types
        ASYNCHRONOUS_MESSAGES = "Asynchronous/Messages"
        SYNCHRONOUS_MESSAGES = "Synchronous/Messages"
        MESSAGE_TYPES = [ASYNCHRONOUS_MESSAGES, SYNCHRONOUS_MESSAGES].freeze

        def initialize(content)
          @content = content
        end

        def self.for(content)
          new(content)
        end

        # Pre-v4 messages live in the "messages" array; v4 messages are typed interactions in the
        # "interactions" array.
        #
        # @return [Array<Hash>]
        def message_interactions
          @message_interactions ||= hashes(content.messages) + hashes(content.interactions).select { |i| message_type?(i) }
        end

        # @return [Array<Hash>]
        def http_interactions
          @http_interactions ||= hashes(content.interactions).reject { |i| message_type?(i) }
        end

        def has_messages?
          message_interactions.any?
        end

        def has_http_interactions?
          http_interactions.any?
        end

        private

        attr_reader :content

        def hashes(entries)
          Array(entries).select { |entry| entry.is_a?(Hash) }
        end

        def message_type?(interaction)
          MESSAGE_TYPES.include?(interaction["type"])
        end
      end
    end
  end
end
