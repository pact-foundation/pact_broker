require 'pact_broker/db'
require 'pact_broker/repositories/helpers'

module PactBroker

  module Domain
    class Verification < Sequel::Model

      set_primary_key :id
      associate(:many_to_one, :pact_version, class: "PactBroker::Pacts::PactVersion", key: :pact_version_id, primary_key: :id)

      def before_create
        super
        self.execution_date ||= DateTime.now
      end

      dataset_module do
        include PactBroker::Repositories::Helpers

        # Expects to be joined with AllPactPublications or subclass
        # Beware that when columns with the same name exist in both datasets
        # you may get the wrong column back in your model.

        def consumer consumer_name
          where(name_like(:consumer_name, consumer_name))
        end

        def provider provider_name
          where(name_like(:provider_name, provider_name))
        end

        def consumer_version_number number
          where(name_like(:consumer_version_number, number))
        end

        def pact_version_sha sha
          where(pact_version_sha: sha)
        end

        def verification_number number
          where(Sequel.qualify("verifications", "number") => number)
        end

        def tag tag_name
          filter = name_like(Sequel.qualify(:tags, :name), tag_name)
          join(:pact_publications, {pact_version_id: :pact_version_id})
            .join(:tags, {version_id: :consumer_version_id}).where(filter)
        end

        def untagged
          join(:pact_publications, {pact_version_id: :pact_version_id})
            .left_outer_join(:tags, {version_id: :consumer_version_id})
            .where(Sequel.qualify(:tags, :name) => nil)
        end
      end

      def pact_version_sha
        pact_version.sha
      end

      def consumer_name
        consumer.name
      end

      def provider_name
        provider.name
      end

      def consumer
        Pacticipant.find(id: PactBroker::Pacts::AllPactPublications
           .where(pact_version_id: pact_version_id)
           .limit(1).select(:consumer_id))
      end

      def provider
        Pacticipant.find(id: PactBroker::Pacts::AllPactPublications
           .where(pact_version_id: pact_version_id)
           .limit(1).select(:provider_id))
      end

      def latest_pact_publication
        pact_version.latest_pact_publication
      end

    end

    Verification.plugin :timestamps
  end
end
