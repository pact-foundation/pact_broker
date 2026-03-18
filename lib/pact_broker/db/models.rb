
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

  module Db
    module Models
      def self.each_integration_model
        INTEGRATIONS_TABLES.each do | model |
          yield model
        end
      end
    end
  end
end
