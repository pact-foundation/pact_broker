module PactBroker
  module Api
    module Resources
      module WebhookResourceMethods
        def webhook_validation_errors?(webhook, uuid = nil)
          errors = webhook_service.errors(webhook, uuid)
          if !errors.empty?
            set_json_validation_error_messages(errors.messages)
            true
          else
            false
          end
        end
      end
    end
  end
end
