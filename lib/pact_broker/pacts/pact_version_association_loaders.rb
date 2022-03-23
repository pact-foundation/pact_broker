require "pact_broker/verifications/latest_verification_id_for_pact_version_and_provider_version"

module PactBroker
  module Pacts
    module PactVersionAssociationLoaders

      LATEST_MAIN_BRANCH_VERIFICATION = lambda {
        providers_join = {
          Sequel[:providers][:id] => Sequel[:latest_verification_id_for_pact_version_and_provider_version][:provider_id]
        }

        branch_versions_join = {
          Sequel[:latest_verification_id_for_pact_version_and_provider_version][:provider_version_id] => Sequel[:branch_versions][:version_id],
          Sequel[:providers][:main_branch] => Sequel[:branch_versions][:branch_name]
        }
        max_verification_id_for_pact_version =  PactBroker::Verifications::LatestVerificationIdForPactVersionAndProviderVersion
                                                  .join(:pacticipants, providers_join, { table_alias: :providers })
                                                  .join(:branch_versions, branch_versions_join)
                                                  .select(Sequel.function(:max, :verification_id))
                                                  .where(pact_version_id: id)
        PactBroker::Domain::Verification.where(id: max_verification_id_for_pact_version)
      }

      LATEST_VERIFICATION_DATASET = lambda {
        PactBroker::Domain::Verification
          .where(
            id: PactBroker::Verifications::LatestVerificationIdForPactVersionAndProviderVersion.select(
              Sequel.function(:max, :verification_id)
            ).where(pact_version_id: id)
          )
      }

      LATEST_CONSUMER_VERSION_LAZY_LOADER = lambda { | ds | ds.unlimited.order(Sequel.desc(:order)).limit(1) }
    end
  end
end
