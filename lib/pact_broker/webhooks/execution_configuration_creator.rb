require "pact_broker/configuration"
require "pact_broker/services"
require "pact_broker/webhooks/execution_configuration"

module PactBroker
  module Webhooks
    class ExecutionConfigurationCreator
      extend PactBroker::Services

      def self.call(resource)
        PactBroker::Webhooks::ExecutionConfiguration.new
          .with_show_response(PactBroker.configuration.show_webhook_response?)
          .with_redact_sensitive_data(PactBroker.configuration.webhook_redact_sensitive_data)
          .with_retry_schedule(PactBroker.configuration.webhook_retry_schedule)
          .with_http_success_codes(PactBroker.configuration.webhook_http_code_success)
          .with_user_agent(PactBroker.configuration.user_agent)
          .with_disable_ssl_verification(PactBroker.configuration.disable_ssl_verification)
          .with_cert_store(certificate_service.cert_store)
          .with_webhook_context(base_url: resource.base_url)
      end
    end
  end
end
