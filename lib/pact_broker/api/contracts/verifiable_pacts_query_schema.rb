require 'dry-validation'

module PactBroker
  module Api
    module Contracts
      class VerifiablePactsQuerySchema
        SCHEMA = Dry::Validation.Schema do
          optional(:provider_version_tags).maybe(:array?)

          optional(:consumer_version_selectors).each do
            schema do
              required(:tag).filled(:str?)
            end
          end
        end

        def self.call(params)
          flatten_messages(SCHEMA.call(params).messages(full: true))
        end

        def self.flatten_messages(messages)
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
