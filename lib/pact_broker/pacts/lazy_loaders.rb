module PactBroker
  module Pacts
    module LazyLoaders
      HEAD_PACT_PUBLICATIONS_FOR_TAGS = lambda {
        consumer_version_tag_names = PactBroker::Domain::Tag.select(:name).where(version_id: consumer_version_id)
          PactPublication
            .for_consumer(consumer)
            .for_provider(provider)
            .latest_for_consumer_tag(consumer_version_tag_names)
            .from_self.order_by(:tag_name)
      }

      LATEST_VERIFICATION_FOR_CONSUMER_BRANCHES = lambda {
        bv_pp_join = {
          Sequel[:branch_versions][:version_id] => Sequel[:pact_publications][:consumer_version_id],
          Sequel[:pact_publications][:provider_id] => provider_id
        }

        verifications_join = {
          Sequel[:verifications][:pact_version_id] => Sequel[:pact_publications][:pact_version_id]
        }

        branch_ids = PactBroker::Versions::BranchVersion
          .select(:branch_id)
          .where(version_id: consumer_version_id)


        latest_verification_id = PactBroker::Versions::BranchVersion
          .select(Sequel[:verifications][:id])
          .where(Sequel[:branch_versions][:branch_id] => branch_ids)
          .join(:pact_publications, bv_pp_join)
          .join(:verifications, verifications_join)
          .order(Sequel.desc(Sequel[:verifications][:id]))
          .limit(1)

        PactBroker::Domain::Verification.where(id: latest_verification_id)
      }
    end
  end
end
