require "json"
require "sequel"
require "pact_broker/repositories/helpers"
require "pact_broker/tags/tag_with_latest_flag"
require "pact_broker/pacts/content"
require "sequel/extensions/symbol_aref_refinement"


module PactBroker
  module Domain
    class Verification < Sequel::Model
      using Sequel::SymbolAref

      set_primary_key :id
      associate(:many_to_one, :pact_version, class: "PactBroker::Pacts::PactVersion", key: :pact_version_id, primary_key: :id)
      associate(:many_to_one, :provider_version, class: "PactBroker::Domain::Version", key: :provider_version_id, primary_key: :id)
      associate(:many_to_one, :provider, class: "PactBroker::Domain::Pacticipant", key: :provider_id, primary_key: :id)
      associate(:many_to_one, :consumer, class: "PactBroker::Domain::Pacticipant", key: :consumer_id, primary_key: :id)
      associate(:one_to_many, :provider_version_tags, :class => "PactBroker::Domain::Tag", primary_key: :provider_version_id, key: :version_id)
      plugin :serialization, :json, :test_results

      def before_create
        super
        self.execution_date ||= DateTime.now
      end

      dataset_module do
        include PactBroker::Repositories::Helpers

        def latest_verification_ids_for_all_consumer_version_tags
          verif_pact_join = { Sequel[:verifications][:pact_version_id] => Sequel[:lpp][:pact_version_id] }
          tag_join = { Sequel[:lpp][:consumer_version_id] => Sequel[:cvt][:version_id] }
          verisons_join = { Sequel[:v][:provider_version_id] => Sequel[:pv][:id] }

          db[:verifications]
            .select_group(
              Sequel[:pv][:pacticipant_id].as(:provider_id),
              Sequel[:lpp][:consumer_id],
              Sequel[:cvt][:name].as(:consumer_version_tag_name)
            )
            .select_append{ max(verifications[id]).as(latest_verification_id) }
            .join(:latest_pact_publication_ids_for_consumer_versions, verif_pact_join, { table_alias: :lpp } )
            .join(:tags, tag_join, { table_alias: :cvt })
            .join(:versions, verisons_join, { table_alias: :pv })
        end

        # Do not use this query. It performs worse than the view.
        # Keeping for posterity
        def latest_verifications_for_all_consumer_version_tags
          verif_pact_join = { Sequel[:v][:pact_version_id] => Sequel[:lpp][:pact_version_id] }
          tag_join = { Sequel[:lpp][:consumer_version_id] => Sequel[:cvt][:version_id] }
          verisons_join = { Sequel[:v][:provider_version_id] => Sequel[:pv][:id] }

          base_query = db[Sequel.as(:latest_verification_id_for_pact_version_and_provider_version, :v)]
            .select(:v[:verification_id], :pv[:pacticipant_id].as(:provider_id), :lpp[:consumer_id], :cvt[:name].as(:consumer_version_tag_name))
            .join(:latest_pact_publication_ids_for_consumer_versions, verif_pact_join, { table_alias: :lpp } )
            .join(:tags, tag_join, { table_alias: :cvt })
            .join(:versions, verisons_join, { table_alias: :pv })


          base_join = {
            :pv[:pacticipant_id] => :v2[:provider_id],
            :lpp[:consumer_id] => :v2[:consumer_id],
            :cvt[:name] => :v2[:consumer_version_tag_name]
          }

          thing = base_query
            .left_join(base_query, base_join, { table_alias: :v2 }) do | _table, _joined_table, _something |
              :v2[:verification_id] > :v[:verification_id]
            end.where(:v2[:verification_id] => nil)

          where(id: thing.from_self.select(:verification_id))
        end

        def latest_verification_ids_for_consumer_version_tags(consumer_ids, consumer_version_tag_names)
          pact_join = { :verifications[:pact_version_id] => :lpp[:pact_version_id], :lpp[:consumer_id] => consumer_ids }
          tag_join = { :lpp[:consumer_version_id] => :cvt[:version_id], :cvt[:name] => consumer_version_tag_names }
          provider_versions_join = { :verifications[:provider_version_id] => :pv[:id] }

          db[Sequel.as(:latest_verification_id_for_pact_version_and_provider_version, :verifications)]
            .select_group(
              :pv[:pacticipant_id].as(:provider_id),
              :lpp[:consumer_id],
              :cvt[:name].as(:consumer_version_tag_name)
            )
            .select_append{ max(verifications[verification_id]).as(latest_verification_id) }
            .join(:latest_pact_publication_ids_for_consumer_versions, pact_join, { table_alias: :lpp } )
            .join(:tags, tag_join, { table_alias: :cvt })
            .join(:versions, provider_versions_join, { table_alias: :pv })
            .where(:verifications[:consumer_id] => consumer_ids)
        end

        # Do not use this query. It performs worse than the view.
        # Keeping for posterity
        def latest_verifications_for_consumer_version_tags(consumer_ids, consumer_version_tag_names)
          latest_ids_for_cv_tags = latest_verification_ids_for_consumer_version_tags(consumer_ids, consumer_version_tag_names)
          join_cols = {
            Sequel[:verifications][:id] => Sequel[:t2][:latest_verification_id]
          }
          select_all_qualified
            .select_append(Sequel[:t2][:consumer_version_tag_name])
            .where(Sequel[:verifications][:consumer_id] => consumer_ids)
            .join(latest_ids_for_cv_tags, join_cols, { table_alias: :t2 })
        end

        # Expects to be joined with AllPactPublications or subclass
        # Beware that when columns with the same name exist in both datasets
        # you may get the wrong column back in your model.

        def delete
          require "pact_broker/webhooks/triggered_webhook"
          PactBroker::Webhooks::TriggeredWebhook.where(verification: self).delete
          super
        end

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
          join(:tags, { version_id: :consumer_version_id }).where(filter)
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

      def provider_version_number
        provider_version.number
      end

      def provider_version_tag_names
        provider_version.tags.collect(&:name)
      end

      def latest_pact_publication
        pact_version.latest_pact_publication
      end

      def interactions_missing_test_results
        @interactions_missing_test_results ||= pact_content_with_test_results.interactions_missing_test_results
      end

      def all_interactions_missing_test_results?
        pact_content_with_test_results.interactions.count == pact_content_with_test_results.interactions_missing_test_results.count
      end

      def pact_content_with_test_results
        @pact_content_with_test_results = PactBroker::Pacts::Content.from_json(pact_version.content).with_test_results(test_results)
      end

      # So consumer_version_tag_name can be accessed by method name
      def method_missing(m, *args, &block)
        if values.key?(m) && args.size == 0
          values[m]
        else
          super
        end
      end
    end

    Verification.plugin :timestamps
  end
end

# Table: verifications
# Columns:
#  id                  | integer                     | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  number              | integer                     |
#  success             | boolean                     | NOT NULL
#  provider_version    | text                        |
#  build_url           | text                        |
#  pact_version_id     | integer                     | NOT NULL
#  execution_date      | timestamp without time zone | NOT NULL
#  created_at          | timestamp without time zone | NOT NULL
#  provider_version_id | integer                     |
#  test_results        | text                        |
#  consumer_id         | integer                     |
#  provider_id         | integer                     |
#  wip                 | boolean                     | NOT NULL DEFAULT false
# Indexes:
#  verifications_pkey                          | PRIMARY KEY btree (id)
#  verifications_pact_version_id_number_index  | UNIQUE btree (pact_version_id, number)
#  verifications_consumer_id_index             | btree (consumer_id)
#  verifications_provider_id_consumer_id_index | btree (provider_id, consumer_id)
#  verifications_provider_id_index             | btree (provider_id)
# Foreign key constraints:
#  fk_verifications_versions          | (provider_version_id) REFERENCES versions(id)
#  verifications_consumer_id_fkey     | (consumer_id) REFERENCES pacticipants(id)
#  verifications_pact_version_id_fkey | (pact_version_id) REFERENCES pact_versions(id)
#  verifications_provider_id_fkey     | (provider_id) REFERENCES pacticipants(id)
# Referenced By:
#  triggered_webhooks                                           | triggered_webhooks_verification_id_fkey      | (verification_id) REFERENCES verifications(id)
#  latest_verification_id_for_pact_version_and_provider_version | latest_v_id_for_pv_and_pv_verification_id_fk | (verification_id) REFERENCES verifications(id) ON DELETE CASCADE
