module PactBroker
  module Api
    module Resources
      module WebhookResourceMethods
        def webhook_validation_errors? webhook
          errors = webhook_service.errors(webhook)
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
