require "pact_broker/dataset"
require "json"
require "pact_broker/pacts/content"
require "sequel/extensions/symbol_aref_refinement"

module PactBroker
  module Domain
    class Verification < Sequel::Model
      using Sequel::SymbolAref
      TO_JSON = lambda { | thing | Sequel.object_to_json(thing) }
      FROM_JSON_WITH_SYMBOL_KEYS = lambda { | json | JSON.parse(json, symbolize_names: true) }

      set_primary_key :id
      associate(:many_to_one, :pact_version, class: "PactBroker::Pacts::PactVersion", key: :pact_version_id, primary_key: :id)
      associate(:many_to_one, :provider_version, class: "PactBroker::Domain::Version", key: :provider_version_id, primary_key: :id)
      associate(:many_to_one, :provider, class: "PactBroker::Domain::Pacticipant", key: :provider_id, primary_key: :id)
      associate(:many_to_one, :consumer, class: "PactBroker::Domain::Pacticipant", key: :consumer_id, primary_key: :id)
      associate(:one_to_many, :provider_version_tags, :class => "PactBroker::Domain::Tag", primary_key: :provider_version_id, key: :version_id)
      plugin :serialization, :json, :test_results, :tag_names
      serialize_attributes [TO_JSON, FROM_JSON_WITH_SYMBOL_KEYS], :consumer_version_selector_hashes

      def before_create
        super
        self.execution_date ||= DateTime.now
      end

      dataset_module do
        include PactBroker::Dataset

        def for_provider_name(provider_name)
          where(provider: PactBroker::Domain::Pacticipant.find_by_name(provider_name))
        end

        def for_consumer_name(consumer_name)
          where(consumer: PactBroker::Domain::Pacticipant.find_by_name(consumer_name))
        end

        # TODO optimise this
        def from_provider_main_branch
          providers_join = {
            Sequel[:verifications][:provider_id] => Sequel[:providers][:id]
          }

          branch_versions_join = {
            Sequel[:verifications][:provider_version_id] => Sequel[:branch_versions][:version_id],
            Sequel[:providers][:main_branch] => Sequel[:branch_versions][:branch_name]
          }

          join(:pacticipants, providers_join, { table_alias: :providers })
            .join(:branch_versions, branch_versions_join)
        end

        # TODO change this to a group by
        def latest_by_pact_version
          base_query = self
          base_join = {
            Sequel[:verifications][:pact_version_id] => Sequel[:v2][:pact_version_id]
          }

          if no_columns_selected?
            base_query = base_query.select_all_qualified
          end

          base_query.left_join(:latest_verification_id_for_pact_version_and_provider_version, base_join, { table_alias: :v2 }) do
            Sequel[:v2][:verification_id] > Sequel[:verifications][:id]
          end
          .where(Sequel[:v2][:verification_id] => nil)
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

        def remove_verifications_for_overridden_consumer_versions
          join(:latest_pact_publication_ids_for_consumer_versions, { pact_version_id: :pact_version_id } )
        end

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

        def join_pact_publications
          join(:pact_publications, { Sequel[:pact_publications][:pact_version_id] => Sequel[:verifications][:pact_version_id] })
        end

        def for_consumer_name_and_consumer_version_number(consumer_name, consumer_version_number)
          consumer_versions = PactBroker::Domain::Version.select(:id).where_pacticipant_name_and_version_number(consumer_name, consumer_version_number)
          join(:pact_publications, {
            Sequel[:pact_publications][:pact_version_id] => Sequel[:verifications][:pact_version_id],
            Sequel[:pact_publications][:consumer_version_id] => consumer_versions
          })
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

      # Whether the pact content was pending at the time the verification was run
      def pact_pending?
        pact_pending
      end

      def failed_and_pact_pending?
        !success && pact_pending
      end

      # So consumer_version_tag_name can be accessed by method name
      def method_missing(m, *args, **kwargs, &block)
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
#  id                               | integer                     | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  number                           | integer                     |
#  success                          | boolean                     | NOT NULL
#  provider_version                 | text                        |
#  build_url                        | text                        |
#  pact_version_id                  | integer                     | NOT NULL
#  execution_date                   | timestamp without time zone | NOT NULL
#  created_at                       | timestamp without time zone | NOT NULL
#  provider_version_id              | integer                     |
#  test_results                     | text                        |
#  consumer_id                      | integer                     |
#  provider_id                      | integer                     |
#  wip                              | boolean                     | NOT NULL DEFAULT false
#  consumer_version_selector_hashes | text                        |
#  tag_names                        | text                        |
#  pact_pending                     | boolean                     |
#  verified_by_implementation       | text                        |
#  verified_by_version              | text                        |
# Indexes:
#  verifications_pkey                          | PRIMARY KEY btree (id)
#  verifications_pact_version_id_number_index  | UNIQUE btree (pact_version_id, number)
#  verifications_consumer_id_index             | btree (consumer_id)
#  verifications_pact_version_id_id_index      | btree (pact_version_id, id)
#  verifications_provider_id_consumer_id_index | btree (provider_id, consumer_id)
#  verifications_provider_id_index             | btree (provider_id)
# Foreign key constraints:
#  fk_verifications_versions          | (provider_version_id) REFERENCES versions(id)
#  verifications_consumer_id_fkey     | (consumer_id) REFERENCES pacticipants(id)
#  verifications_pact_version_id_fkey | (pact_version_id) REFERENCES pact_versions(id)
#  verifications_provider_id_fkey     | (provider_id) REFERENCES pacticipants(id)
# Referenced By:
#  latest_verification_id_for_pact_version_and_provider_version | latest_v_id_for_pv_and_pv_verification_id_fk               | (verification_id) REFERENCES verifications(id) ON DELETE CASCADE
#  pact_version_provider_tag_successful_verifications           | pact_version_provider_tag_successful_verifications_v_id_fk | (verification_id) REFERENCES verifications(id) ON DELETE SET NULL
#  triggered_webhooks                                           | triggered_webhooks_verification_id_fkey                    | (verification_id) REFERENCES verifications(id)
