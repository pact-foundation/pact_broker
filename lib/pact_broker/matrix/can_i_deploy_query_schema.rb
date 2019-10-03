require 'dry-validation'

module PactBroker
  module Api
    module Contracts
      class CanIDeployQuerySchema
        SCHEMA = Dry::Validation.Schema do
          required(:pacticipant).filled(:str?)
          required(:version).filled(:str?)
          optional(:to).filled(:str?)
        end

        def self.call(params)
          select_first_message(SCHEMA.call(params).messages(full: true))
        end

        def self.select_first_message(messages)
          messages.each_with_object({}) do | (key, value), new_messages |
            new_messages[key] = [value.first]
          end
        end
      end
    end
  end
end
