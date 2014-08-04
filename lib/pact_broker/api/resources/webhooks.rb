require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/webhook_decorator'

module PactBroker::Api

  module Resources

    class Webhooks < BaseResource

      def content_types_accepted
        [["application/json", :from_json]]
      end

      def allowed_methods
        ["POST"]
      end

      def resource_exists?
        (@consumer = find_pacticipant(identifier_from_path[:consumer_name], "consumer")) &&
          (@provider = find_pacticipant(identifier_from_path[:provider_name], "provider"))
      end

      def malformed_request?
        if request.post?
          begin
            @webhook = Decorators::WebhookDecorator.new(PactBroker::Models::Webhook.new).from_json(request.body.to_s)
            false
          rescue
            set_json_error_message 'Invalid JSON'
            true
          end
        end
      end

      def set_json_error_message message
        response.headers['Content-Type'] = 'application/json'
        response.body = {error: message}.to_json
      end

      def process_post
        true
      end

      def from_json

      end

      private

      def find_pacticipant name, role
        pacticipant = pacticipant_service.find_pacticipant_by_name name
        if pacticipant.nil?
          set_json_error_message "No #{role} with name '#{name}' found"
          false
        else
          true
        end
      end

    end
  end

end
