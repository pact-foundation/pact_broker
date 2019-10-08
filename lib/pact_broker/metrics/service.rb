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
require 'pact_broker/matrix/row'
require 'pact_broker/matrix/head_row'

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
          pactRevisions: {
            counts: pact_revision_counts
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
          },
          matrix: {
            count: PactBroker::Matrix::Row.count
          },
          headMatrix: {
            count: PactBroker::Matrix::HeadRow.count
          }
        }
      end

      def pact_revision_counts
        query = "select revision_count as number_of_revisions, count(consumer_version_id) as consumer_version_count
          from (select consumer_version_id, count(*) as revision_count from pact_publications group by consumer_version_id) foo
          group by revision_count"
        PactBroker::Pacts::PactPublication.db[query].all.each_with_object({}) { |row, hash| hash[row[:number_of_revisions]] = row[:consumer_version_count] }
      end
    end
  end
end
