require 'dry-validation'
require 'pact_broker/messages'

module PactBroker
  module Api
    module Contracts
      class CanIDeployQuerySchema
        extend PactBroker::Messages

        SCHEMA = Dry::Validation.Schema do
          required(:pacticipant).filled(:str?)
          required(:version).filled(:str?)
          optional(:to).filled(:str?)
          optional(:environment).filled(:str?)
        end

        def self.call(params)
          result = select_first_message(SCHEMA.call(params).messages(full: true))
          if params[:to] && params[:environment]
            result[:to] ||= []
            result[:to] << message("errors.validation.cannot_specify_tag_and_environment")
          end
          result
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
