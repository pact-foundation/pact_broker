require "pact_broker/webhooks/execution"
require "pact_broker/webhooks/triggered_webhook"
require "pact_broker/webhooks/webhook"
require "pact_broker/pacts/latest_pact_publication_id_for_consumer_version"
require "pact_broker/verifications/latest_verification_id_for_pact_version_and_provider_version"
require "pact_broker/integrations/integration"
require "pact_broker/pacts/pact_publication"
require "pact_broker/pacts/pact_version"
require "pact_broker/domain/verification"
require "pact_broker/domain/tag"
require "pact_broker/domain/version"
require "pact_broker/domain/label"
require "pact_broker/domain/pacticipant"
require "pact_broker/deployments/environment"
require "pact_broker/deployments/deployed_version"
require "pact_broker/deployments/released_version"
require "pact_broker/matrix/row"
require "pact_broker/matrix/head_row"
require "pact_broker/versions/branch"
require "pact_broker/versions/branch_version"
require "pact_broker/versions/branch_head"

module PactBroker
  INTEGRATIONS_TABLES = [
    PactBroker::Webhooks::Execution,
    PactBroker::Webhooks::TriggeredWebhook,
    PactBroker::Webhooks::Webhook,
    PactBroker::Pacts::LatestPactPublicationIdForConsumerVersion,
    PactBroker::Verifications::LatestVerificationIdForPactVersionAndProviderVersion,
    PactBroker::Domain::Verification,
    PactBroker::Pacts::PactPublication,
    PactBroker::Pacts::PactVersion,
    PactBroker::Domain::Tag,
    PactBroker::Deployments::DeployedVersion,
    PactBroker::Deployments::ReleasedVersion,
    PactBroker::Versions::BranchHead,
    PactBroker::Versions::BranchVersion,
    PactBroker::Versions::Branch,
    PactBroker::Domain::Version,
    PactBroker::Domain::Label,
    PactBroker::Domain::Pacticipant
  ]

  module DB
    def self.each_integration_model
      INTEGRATIONS_TABLES.each do | model |
        yield model
      end
    end
  end
end
