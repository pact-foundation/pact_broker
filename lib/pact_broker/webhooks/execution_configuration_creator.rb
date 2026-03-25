
module PactBroker
  module Webhooks
    class ExecutionConfigurationCreator
      extend PactBroker::Services

      def self.call(resource)
        PactBroker::Webhooks::ExecutionConfiguration.new
          .with_show_response(PactBroker::Configuration.configuration.show_webhook_response?)
          .with_redact_sensitive_data(PactBroker::Configuration.configuration.webhook_redact_sensitive_data)
          .with_retry_schedule(PactBroker::Configuration.configuration.webhook_retry_schedule)
          .with_http_success_codes(PactBroker::Configuration.configuration.webhook_http_code_success)
          .with_user_agent(PactBroker::Configuration.configuration.user_agent)
          .with_disable_ssl_verification(PactBroker::Configuration.configuration.disable_ssl_verification)
          .with_cert_store(certificate_service.cert_store)
          .with_webhook_context(base_url: resource.base_url)
      end
    end
  end
end
