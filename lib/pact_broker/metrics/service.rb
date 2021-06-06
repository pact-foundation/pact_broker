require "pact_broker/configuration"
require "pact_broker/pacts/pact_publication"
require "pact_broker/pacts/pact_version"
require "pact_broker/domain/pacticipant"
require "pact_broker/integrations/integration"
require "pact_broker/domain/verification"
require "pact_broker/domain/version"
require "pact_broker/api/decorators/format_date_time"
require "pact_broker/webhooks/webhook"
require "pact_broker/webhooks/triggered_webhook"
require "pact_broker/webhooks/execution"
require "pact_broker/matrix/row"
require "pact_broker/matrix/head_row"

module PactBroker
  module Metrics
    module Service
      include PactBroker::Api::Decorators::FormatDateTime

      extend self

      # rubocop: disable Metrics/MethodLength
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
          pactRevisionsPerConsumerVersion: {
            distribution: pact_revision_counts
          },
          verificationResults: {
            count: PactBroker::Domain::Verification.count,
            successCount: PactBroker::Domain::Verification.where(success: true).count,
            failureCount: PactBroker::Domain::Verification.where(success: false).count,
            distinctCount: PactBroker::Domain::Verification.distinct.select(:provider_version_id, :pact_version_id, :success).count,
            first: format_date_time(PactBroker::Domain::Verification.order(:id).first&.created_at),
            last: format_date_time(PactBroker::Domain::Verification.order(:id).last&.created_at),
          },
          verificationResultsPerPactVersion: {
            distribution: verification_distribution
          },
          pacticipantVersions: {
            count: PactBroker::Domain::Version.count
          },
          webhooks: {
            count: PactBroker::Webhooks::Webhook.count
          },
          tags: {
            count: PactBroker::Domain::Tag.count,
            distinctCount: PactBroker::Domain::Tag.select(:name).distinct.count,
            distinctWithPacticipantCount: PactBroker::Domain::Tag.join(:versions, { id: :version_id }).select_group(:name, Sequel[:versions][:pacticipant_id]).count
          },
          triggeredWebhooks: {
            count: PactBroker::Webhooks::TriggeredWebhook.count
          },
          webhookExecutions: {
            count: PactBroker::Webhooks::Execution.count
          },
          matrix: {
            count: matrix_count
          }
        }
      end
      # rubocop: enable Metrics/MethodLength

      def pact_revision_counts
        query = "select revision_count as number_of_revisions, count(consumer_version_id) as consumer_version_count
          from (select consumer_version_id, count(*) as revision_count from pact_publications group by consumer_version_id) foo
          group by revision_count
          order by 1"
        PactBroker::Pacts::PactPublication.db[query].all.each_with_object({}) { |row, hash| hash[row[:number_of_revisions]] = row[:consumer_version_count] }
      end

      def verification_distribution
        query = "select verification_count as number_of_verifications, count(*) as pact_version_count
          from (select pact_version_id, count(*) as verification_count from verifications group by pact_version_id) foo
          group by verification_count
          order by 1"
          PactBroker::Pacts::PactPublication.db[query].all.each_with_object({}) { |row, hash| hash[row[:number_of_verifications]] = row[:pact_version_count] }
      end

      def matrix_count
        begin
          PactBroker::Matrix::Row.db.with_statement_timeout(PactBroker.configuration.metrics_sql_statement_timeout) do
            PactBroker::Matrix::Row.count
          end
        rescue Sequel::DatabaseError => _ex
          -1
        end
      end
    end
  end
end
