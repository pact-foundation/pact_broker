module PactBroker
  module Api

    module Resources

      module WebhookResourceMethods

        def malformed_webhook_request? webhook
          begin
            if (errors = webhook.validate).any?
              set_json_validation_error_messages errors
              return true
            end
          rescue
            set_json_error_message 'Invalid JSON'
            return true
          end
          false
        end
      end

    end
  end
end