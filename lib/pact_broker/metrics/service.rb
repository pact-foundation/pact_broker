require "pact_broker/configuration"
require "pact_broker/db/models"
require "pact_broker/api/decorators/format_date_time"

module PactBroker
  module Metrics
    module Service
      include PactBroker::Api::Decorators::FormatDateTime

      extend self

      # rubocop: disable Metrics/MethodLength
      def metrics
        {
          interactions: interactions_counts,
          pacticipants: {
            count: PactBroker::Domain::Pacticipant.count,
            withMainBranchSetCount: PactBroker::Domain::Pacticipant.with_main_branch_set.count
          },
          integrations: {
            count: PactBroker::Pacts::PactPublication.select(:consumer_id, :provider_id).distinct.count
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
            count: PactBroker::Domain::Version.count,
            withUserCreatedBranchCount: PactBroker::Domain::Version.with_user_created_branch.count,
            withBranchCount: PactBroker::Domain::Version.with_branch.count,
            withBranchSetCount: PactBroker::Domain::Version.with_branch.count # todo remove when checked it's not used
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
          },
          environments: {
            count: PactBroker::Deployments::Environment.count
          },
          deployedVersions: {
            count: PactBroker::Deployments::DeployedVersion.count,
            userCreatedCount: PactBroker::Deployments::DeployedVersion.user_created.count,
            currentlyDeployedCount: PactBroker::Deployments::DeployedVersion.currently_deployed.count
          },
          releasedVersions: {
            count: PactBroker::Deployments::ReleasedVersion.count,
            currentlySupportedCount: PactBroker::Deployments::ReleasedVersion.currently_supported.count
          }
        }
      end
      # rubocop: enable Metrics/MethodLength

      def interactions_counts
        latest_pact_versions = PactBroker::Pacts::PactVersion.where(
          id: PactBroker::Pacts::PactPublication.overall_latest.from_self.select(:pact_version_id)
        )

        latest_pact_versions.all.each(&:set_interactions_and_messages_counts!)

        counts = latest_pact_versions
          .select(
            Sequel.function(:sum, :interactions_count).as(:interactions_count),
            Sequel.function(:sum, :messages_count).as(:messages_count)
        ).first
        {
          latestInteractionsCount: counts[:interactions_count] || 0,
          latestMessagesCount: counts[:messages_count] || 0,
          latestInteractionsAndMessagesCount: (counts[:interactions_count] || 0) + (counts[:messages_count] || 0)
        }
      end

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
