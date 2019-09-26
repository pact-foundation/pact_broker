require 'dry-validation'

module PactBroker
  module Api
    module Contracts
      class VerifiablePactsQuerySchema
        SCHEMA = Dry::Validation.Schema do
          optional(:provider_version_tags).maybe(:array?)
          # optional(:exclude_other_pending).filled(included_in?: ["true", "false"])
          optional(:consumer_version_selectors).each do
            schema do
              required(:tag).filled(:str?)
            end
          end
        end

        def self.call(params)
          select_first_message(flatten_index_messages(SCHEMA.call(params).messages(full: true)))
        end

        def self.select_first_message(messages)
          messages.each_with_object({}) do | (key, value), new_messages |
            new_messages[key] = [value.first]
          end
        end

        def self.flatten_index_messages(messages)
          if messages[:consumer_version_selectors]
            new_messages = messages[:consumer_version_selectors].collect do | index, value |
              value.values.flatten.collect { | text | "#{text} at index #{index}"}
            end.flatten
            messages.merge(consumer_version_selectors: new_messages)
          else
            messages
          end
        end
      end
    end
  end
end
