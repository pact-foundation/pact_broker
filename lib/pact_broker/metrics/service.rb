require 'pact_broker/pacts/pact_publication'
require 'pact_broker/pacts/pact_version'
require 'pact_broker/domain/pacticipant'
require 'pact_broker/integrations/integration'
require 'pact_broker/domain/verification'
require 'pact_broker/domain/version'
require 'pact_broker/api/decorators/format_date_time'
require 'pact_broker/webhooks/webhook'
require 'pact_broker/webhooks/triggered_webhook'
require 'pact_broker/webhooks/execution'

module PactBroker
  module Metrics
    module Service
      include PactBroker::Api::Decorators::FormatDateTime

      extend self

      def metrics
        {
          pacticipants: {
            count: PactBroker::Domain::Pacticipant.count
          },
          integrations: {
            count: PactBroker::Integrations::Integration.count
          },
          pactPublications: {
            count: PactBroker::Pacts::PactPublication.count,
            first: format_date_time(PactBroker::Pacts::PactPublication.order(:id).first&.created_at),
            last: format_date_time(PactBroker::Pacts::PactPublication.order(:id).last&.created_at)
          },
          pactVersions: {
            count: PactBroker::Pacts::PactVersion.count
          },
          verificationResults: {
            count: PactBroker::Domain::Verification.count,
            first: format_date_time(PactBroker::Domain::Verification.order(:id).first.created_at),
            last: format_date_time(PactBroker::Domain::Verification.order(:id).last.created_at)
          },
          pacticipantVersions: {
            count: PactBroker::Domain::Version.count
          },
          webhooks: {
            count: PactBroker::Webhooks::Webhook.count
          },
          triggeredWebhooks: {
            count: PactBroker::Webhooks::TriggeredWebhook.count
          },
          webhookExecutions: {
            count: PactBroker::Webhooks::Execution.count
          }
        }
      end
    end
  end
end
