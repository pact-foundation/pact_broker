require 'webmachine/adapters/rack_mapped'
require 'webmachine/rack_adapter_monkey_patch'
require 'pact_broker/api/resources'
require 'pact_broker/feature_toggle'

module PactBroker

  API ||= begin
    pact_api = Webmachine::Application.new do |app|
      app.routes do
        add(['trace', :*], Webmachine::Trace::TraceResource) unless ENV['RACK_ENV'] == 'production'

        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'versions'], Api::Resources::PactVersions, {resource_name: "pact_publications"}
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'versions', :consumer_version_number], Api::Resources::Pact, {resource_name: "pact_publication", deprecated: true} # Not the standard URL, but keep for backwards compatibility
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'tag', :tag], Api::Resources::TaggedPactVersions, {resource_name: "tagged_pact_publications"}

        # Pacts
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'version', :consumer_version_number], Api::Resources::Pact, {resource_name: "pact_publication"}
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'pact-version', :pact_version_sha], Api::Resources::PactVersion, {resource_name: "pact_publication"}
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'pact-version', :pact_version_sha, 'metadata', :metadata], Api::Resources::PactVersion, {resource_name: "pact_publication"}
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'version', :consumer_version_number, 'previous-distinct'], Api::Resources::PreviousDistinctPactVersion, {resource_name: "previous_distinct_pact_version"}
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'version', :consumer_version_number, 'diff', 'previous-distinct'], Api::Resources::PactContentDiff, {resource_name: "previous_distinct_pact_version_diff"}
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'version', :consumer_version_number, 'diff', 'version', :comparison_consumer_version], Api::Resources::PactContentDiff, {resource_name: "pact_version_diff_by_consumer_version"}
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'pact-version', :pact_version_sha, 'diff', 'pact-version', :comparison_pact_version_sha], Api::Resources::PactContentDiff, {resource_name: "pact_version_diff_by_pact_version_sha"}

        # Verifications
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'pact-version', :pact_version_sha, 'verification-results'], Api::Resources::Verifications, {resource_name: "verification_results"}
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'pact-version', :pact_version_sha, 'metadata', :metadata, 'verification-results'], Api::Resources::Verifications, {resource_name: "verification_results"}
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'pact-version', :pact_version_sha, 'verification-results', :verification_number], Api::Resources::Verification, {resource_name: "verification_result"}
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'pact-version', :pact_version_sha, 'verification-results', :verification_number, 'triggered-webhooks'], Api::Resources::VerificationTriggeredWebhooks, {resource_name: "verification_result_triggered_webhooks"}
        add ['verification-results', 'consumer', :consumer_name, 'version', :consumer_version_number,'latest'], Api::Resources::LatestVerificationsForConsumerVersion, {resource_name: "verification_results_for_consumer_version"}

        # Badges
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'latest', 'badge'], Api::Resources::Badge, {resource_name: "latest_pact_badge"}
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'latest', :tag, 'badge'], Api::Resources::Badge, {resource_name: "latest_tagged_pact_badge"}
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'latest-untagged', 'badge'], Api::Resources::Badge, {resource_name: "latest_untagged_pact_badge", tag: :untagged}

        # Latest pacts
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'latest'], Api::Resources::LatestPact, {resource_name: "latest_pact_publication"}
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'latest', :tag], Api::Resources::LatestPact, {resource_name: "latest_tagged_pact_publication"}
        add ['pacts', 'provider', :provider_name], Api::Resources::ProviderPacts, {resource_name: "provider_pact_publications"}
        add ['pacts', 'provider', :provider_name, 'tag', :tag], Api::Resources::ProviderPacts, {resource_name: "tagged_provider_pact_publications"}
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'latest-untagged'], Api::Resources::LatestPact, {resource_name: "latest_untagged_pact_publication", tag: :untagged}
        add ['pacts', 'provider', :provider_name, 'latest'], Api::Resources::LatestProviderPacts, {resource_name: "latest_provider_pact_publications"}
        add ['pacts', 'provider', :provider_name, 'latest', :tag], Api::Resources::LatestProviderPacts, {resource_name: "latest_tagged_provider_pact_publications"}
        add ['pacts', 'latest'], Api::Resources::LatestPacts, {resource_name: "latest_pacts"}

        # Pending pacts
        add ['pacts', 'provider', :provider_name, 'pending'], Api::Resources::PendingProviderPacts, {resource_name: "pending_provider_pact_publications"}

        # Deprecated pact
        add ['pact', 'provider', :provider_name, 'consumer', :consumer_name, 'version', :consumer_version_number], Api::Resources::Pact, {resource_name: "pact_publications", deprecated: "true"} # Deprecate, singular /pact
        add ['pact', 'provider', :provider_name, 'consumer', :consumer_name, 'latest'], Api::Resources::LatestPact, {resource_name: "latest_pact_publications", deprecated: "true"}

        # Pacticipants
        add ['pacticipants'], Api::Resources::Pacticipants, {resource_name: "pacticipants"}
        add ['pacticipants', 'label', :label_name], PactBroker::Api::Resources::PacticipantsForLabel, {resource_name: "pacticipants_for_label"}
        add ['pacticipants', :pacticipant_name], Api::Resources::Pacticipant, {resource_name: "pacticipant"}
        add ['pacticipants', :pacticipant_name, 'versions'], Api::Resources::Versions, {resource_name: "pacticipant_versions"}
        add ['pacticipants', :pacticipant_name, 'versions', :pacticipant_version_number], Api::Resources::Version, {resource_name: "pacticipant_version"}
        add ['pacticipants', :pacticipant_name, 'latest-version', :tag], Api::Resources::Version, {resource_name: "latest_tagged_pacticipant_version"}
        add ['pacticipants', :pacticipant_name, 'latest-version'], Api::Resources::Version, {resource_name: "latest_pacticipant_version"}
        add ['pacticipants', :pacticipant_name, 'versions', :pacticipant_version_number, 'tags', :tag_name], Api::Resources::Tag, {resource_name: "pacticipant_version_tag"}
        add ['pacticipants', :pacticipant_name, 'labels', :label_name], Api::Resources::Label, {resource_name: "pacticipant_label"}

        # Webhooks
        add ['webhooks', 'provider', :provider_name, 'consumer', :consumer_name ], Api::Resources::Webhooks, {resource_name: "consumer_and_provider_webhooks"}
        add ['webhooks', 'provider', :provider_name], Api::Resources::Webhooks, {resource_name: "provider_webhooks"}
        add ['webhooks', 'consumer', :consumer_name], Api::Resources::Webhooks, {resource_name: "consumer_webhooks"}
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'webhooks'], Api::Resources::PactWebhooks, {resource_name: "pact_webhooks"}
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'webhooks', 'status'], Api::Resources::PactWebhooksStatus, {resource_name: "pact_webhooks_status"}
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'version', :consumer_version_number, 'triggered-webhooks'], Api::Resources::PactTriggeredWebhooks, {resource_name: "pact_triggered_webhooks"}

        add ['webhooks', 'execute' ], Api::Resources::WebhookExecution, {resource_name: "execute_unsaved_webhook"}
        add ['webhooks', :uuid ], Api::Resources::Webhook, {resource_name: "webhook"}
        add ['webhooks', :uuid, 'trigger', :trigger_uuid, 'logs' ], Api::Resources::TriggeredWebhookLogs, {resource_name: "triggered_webhook_logs"}
        add ['webhooks', :uuid, 'execute' ], Api::Resources::WebhookExecution, {resource_name: "execute_webhook"}
        add ['webhooks'], Api::Resources::AllWebhooks, {resource_name: "webhooks"}

        add ['relationships'], Api::Resources::Relationships, {resource_name: "relationships"}
        add ['groups', :pacticipant_name], Api::Resources::Group, {resource_name: "group"}

        # matrix
        add ['matrix', 'provider', :provider_name, 'consumer', :consumer_name], Api::Resources::MatrixForConsumerAndProvider, {resource_name: "matrix_consumer_provider"}
        add ['matrix', 'provider', :provider_name, 'latest', :provider_tag, 'consumer', :consumer_name, 'latest', :tag, 'badge'], Api::Resources::MatrixBadge, {resource_name: "matrix_tag_badge"}
        add ['matrix'], Api::Resources::Matrix, {resource_name: "matrix"}

        add ['dashboard'], Api::Resources::Dashboard, {resource_name: "dashboard"}
        add ['dashboard', 'provider', :provider_name, 'consumer', :consumer_name ], Api::Resources::Dashboard, {resource_name: "integration_dashboard"}
        add ['test','error'], Api::Resources::ErrorTest, {resource_name: "error_test"}

        add ['integrations'], Api::Resources::Integrations, {resource_name: "integrations"}
        add ['integrations', 'provider', :provider_name, 'consumer', :consumer_name], Api::Resources::Integration, {resource_name: "integration"}
        add [], Api::Resources::Index, {resource_name: "index"}
      end
    end

    pact_api.configure do |config|
      config.adapter = :RackMapped
    end

    pact_api.adapter
  end
end
