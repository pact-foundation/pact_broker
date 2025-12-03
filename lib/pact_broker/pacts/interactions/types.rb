module PactBroker
  module Pacts
    module Interactions
      class Types
        # Pact Spec v4+ message interaction types
        MESSAGE_TYPES = [
          "Asynchronous/Messages",
          "Synchronous/Messages"
        ].freeze

        def initialize(content)
          @content = content
        end

        def self.for(content)
          new(content)
        end

        def has_messages?
          if spec_version < 4.0
            # Pre-v4: messages in "messages" key
            content.messages&.any? || false
          else
            # V4+: messages are typed interactions
            content.interactions&.any? { |i| message_interaction?(i) } || false
          end
        end

        private

        attr_reader :content

        def message_interaction?(interaction)
          interaction.is_a?(Hash) &&
            MESSAGE_TYPES.include?(interaction["type"])
        end

        def spec_version
          content.pact_specification_version.to_f
        end
      end
    end
  end
end
