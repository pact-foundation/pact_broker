require "pact_broker/pacts/pact_publication_selector_dataset_module"

module PactBroker
  module Pacts
    module PactPublicationDatasetModule
      include PactPublicationSelectorDatasetModule

      def for_consumer_id_and_provider_id(consumer_id, provider_id)
        where(Sequel[:pact_publications][:consumer_id] => consumer_id, Sequel[:pact_publications][:provider_id] => provider_id)
      end

      def for_provider_name(provider_name)
        where(provider: PactBroker::Domain::Pacticipant.find_by_name(provider_name))
      end

      def for_consumer_name(consumer_name)
        where(consumer: PactBroker::Domain::Pacticipant.find_by_name(consumer_name))
      end

      def for_provider provider
        where(provider: provider)
      end

      def for_consumer consumer
        where(consumer: consumer)
      end

      def for_consumer_version_tag tag_name
        base_query = self
        if no_columns_selected?
          base_query = base_query.select_all_qualified.select_append(Sequel[:tags][:name].as(:tag_name))
        end

        base_query.join(:tags, { version_id: :consumer_version_id, Sequel[:tags][:name] => tag_name })
      end

      def for_consumer_name_and_maybe_version_number(consumer_name, consumer_version_number)
        if consumer_version_number
          where(consumer_version: PactBroker::Domain::Version.where_pacticipant_name_and_version_number(consumer_name, consumer_version_number))
        else
          where(consumer: PactBroker::Domain::Pacticipant.find_by_name(consumer_name))
        end
      end

      def latest_by_consumer_branch
        branch_versions_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:branch_versions][:version_id]
        }

        branches_join = {
          Sequel[:branch_versions][:branch_id] => Sequel[:branches][:id]
        }

        max_orders = join(:branch_versions, branch_versions_join)
                      .join(:branches, branches_join)
                      .select_group(Sequel[:branches][:pacticipant_id].as(:consumer_id), Sequel[:branches][:name].as(:branch_name))
                      .select_append{ max(consumer_version_order).as(latest_consumer_version_order) }

        max_join = {
          Sequel[:max_orders][:consumer_id] => Sequel[:pact_publications][:consumer_id],
          Sequel[:max_orders][:latest_consumer_version_order] => Sequel[:pact_publications][:consumer_version_order]
        }

        base_query = self
        if no_columns_selected?
          base_query = base_query.select_all_qualified.select_append(Sequel[:max_orders][:branch_name].as(:branch))
        end

        base_query
          .remove_overridden_revisions
          .join(max_orders, max_join, { table_alias: :max_orders })
      end

      def overall_latest
        self_join = {
          Sequel[:pact_publications][:consumer_id] => Sequel[:pp2][:consumer_id],
          Sequel[:pact_publications][:provider_id] => Sequel[:pp2][:provider_id]
        }

        base_query = self
        base_query = base_query.select_all_qualified if no_columns_selected?

        base_query.left_join(base_query.select(:consumer_id, :provider_id, :consumer_version_order), self_join, { table_alias: :pp2 } ) do
          Sequel[:pp2][:consumer_version_order] > Sequel[:pact_publications][:consumer_version_order]
        end
        .where(Sequel[:pp2][:consumer_version_order] => nil)
        .remove_overridden_revisions_from_complete_query
      end

      def overall_latest_for_consumer_id_and_provider_id(consumer_id, provider_id)
        for_consumer_id_and_provider_id(consumer_id, provider_id)
          .order(Sequel.desc(Sequel[:pact_publications][:consumer_version_order]), Sequel.desc(:revision_number))
          .limit(1)
      end

      def latest_for_consumer_branch(branch_name)
        branch_versions_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:branch_versions][:version_id]
        }

        # TODO use name like
        branches_join = {
          Sequel[:branch_versions][:branch_id] => Sequel[:branches][:id],
          Sequel[:branches][:name] => branch_name
        }

        max_orders = join(:branch_versions, branch_versions_join)
                      .join(:branches, branches_join)
                      .select_group(:consumer_id, Sequel[:branches][:name].as(:branch_name))
                      .select_append{ max(consumer_version_order).as(latest_consumer_version_order) }

        max_join = {
          Sequel[:max_orders][:consumer_id] => Sequel[:pact_publications][:consumer_id],
          Sequel[:max_orders][:latest_consumer_version_order] => Sequel[:pact_publications][:consumer_version_order]
        }

        base_query = self
        if no_columns_selected?
          base_query = base_query.select_all_qualified.select_append(Sequel[:max_orders][:branch_name].as(:branch))
        end
        base_query
          .join(max_orders, max_join, { table_alias: :max_orders })
          .remove_overridden_revisions_from_complete_query
      end

      def latest_by_consumer_tag
        tags_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:tags][:version_id]
        }

        base_query = join(:tags, tags_join)

        if no_columns_selected?
          base_query = base_query.select_all_qualified.select_append(Sequel[:tags][:name].as(:tag_name))
        end

        joined_query = base_query.select(
          Sequel[:pact_publications][:consumer_id],
          Sequel[:tags][:version_order],
          Sequel[:tags][:name].as(:tag_name)
        )

        self_join = {
          Sequel[:pact_publications][:consumer_id] => Sequel[:pp2][:consumer_id],
          Sequel[:tags][:name] => Sequel[:pp2][:tag_name]
        }
        base_query.left_join(joined_query, self_join, { table_alias: :pp2 } ) do
          Sequel[:pp2][:version_order] > Sequel[:tags][:version_order]
        end
        .where(Sequel[:pp2][:version_order] => nil)
        .remove_overridden_revisions_from_complete_query
      end

      def latest_for_consumer_tag(tag_name)
        tags_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:tags][:version_id],
          Sequel[:tags][:name] => tag_name
        }

        base_query = self
        if no_columns_selected?
          base_query = base_query.select_all_qualified.select_append(Sequel[:tags][:name].as(:tag_name))
        end

        base_query = base_query
          .join(:tags, tags_join)
          .where(Sequel[:tags][:name] => tag_name)

        joined_query = base_query.select(
          Sequel[:pact_publications][:consumer_id],
          Sequel[:tags][:name].as(:tag_name),
          Sequel[:tags][:version_order]
        )

        self_join = {
          Sequel[:pact_publications][:consumer_id] => Sequel[:pp2][:consumer_id],
          Sequel[:tags][:name] => Sequel[:pp2][:tag_name]
        }

        base_query.left_join(joined_query, self_join, { table_alias: :pp2 } ) do
          Sequel[:pp2][:version_order] > Sequel[:tags][:version_order]
        end
        .where(Sequel[:pp2][:version_order] => nil)
        .remove_overridden_revisions_from_complete_query
      end

      def verified_before_date(date)
        where { Sequel[:verifications][:execution_date] < date }
      end

      def created_after date
        where(Sequel.lit("#{first_source_alias}.created_at > ?", date))
      end

      def remove_overridden_revisions(pact_publications_alias = :pact_publications)
        base = self
        base = base.select_all_qualified if no_columns_selected?
        base.join(:latest_pact_publication_ids_for_consumer_versions, { Sequel[:lp][:pact_publication_id] => Sequel[pact_publications_alias][:id] }, { table_alias: :lp})
      end

      def remove_overridden_revisions_from_complete_query
        from_self(alias: :pact_publications)
          .select(Sequel[:pact_publications].*)
          .remove_overridden_revisions(:pact_publications)
      end

      def for_pact_version_id(pact_version_id)
        where(Sequel[:pact_publications][:pact_version_id] => pact_version_id)
      end

      def join_consumer_versions(table_alias = :cv, extra_join_criteria = {}, &block)
        versions_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[table_alias][:id]
        }.merge(extra_join_criteria)
        join(:versions, versions_join, { table_alias: table_alias }, &block)
      end

      def join_consumer_version_tags(table_alias = :ct)
        join(:tags, { Sequel[table_alias][:version_id] => Sequel[:pact_publications][:consumer_version_id]}, { table_alias: table_alias })
      end

      def join_consumer_version_tags_with_names(consumer_version_tag_names)
        join(:tags, {
          Sequel[:ct][:version_id] => Sequel[:pact_publications][:consumer_version_id],
          Sequel[:ct][:name] => consumer_version_tag_names
        }, {
          table_alias: :ct
        })
      end

      def join_providers(table_alias = :providers, base_table = :pact_publications, extra_join_criteria = {})
        provider_join = {
          Sequel[base_table][:provider_id] => Sequel[table_alias][:id]
        }.merge(extra_join_criteria)
        join(:pacticipants, provider_join, { table_alias: table_alias })
      end

      def join_consumers(table_alias = :consumers, base_table = :pact_publications, extra_join_criteria = {})
        consumer_join = {
          Sequel[base_table][:consumer_id] => Sequel[table_alias][:id]
        }.merge(extra_join_criteria)
        join(:pacticipants, consumer_join, { table_alias: table_alias })
      end

      def join_pact_versions
        join(:pact_versions, { Sequel[:pact_publications][:pact_version_id] => Sequel[:pact_versions][:id] })
      end

      def for_pact_version_sha(pact_version_sha)
        join_pact_versions
          .where(Sequel[:pact_versions][:sha] => pact_version_sha)
      end

      def eager_load_pact_versions
        eager(:pact_versions)
      end

      def tag tag_name
        filter = name_like(Sequel.qualify(:tags, :name), tag_name)
        join(:tags, {version_id: :consumer_version_id}).where(filter)
      end

      def provider_name_like(name)
        where(name_like(Sequel[:providers][:name], name))
      end

      def consumer_name_like(name)
        where(name_like(Sequel[:consumers][:name], name))
      end

      def consumer_version_number_like(number)
        where(name_like(Sequel[:cv][:number], number))
      end

      def consumer_version_tag(tag)
        where(Sequel[:ct][:name] => tag)
      end

      def order_by_consumer_name
        order_append_ignore_case(Sequel[:consumers][:name])
      end

      def order_by_consumer_version_order
        order_append(:consumer_version_order, :revision_number)
      end

      def latest
        order(:consumer_version_order, :revision_number).last
      end

      def where_consumer_if_set(consumer)
        if consumer
          where(consumer: consumer)
        else
          self
        end
      end

      def delete
        require "pact_broker/webhooks/triggered_webhook"
        PactBroker::Webhooks::TriggeredWebhook.where(pact_publication: self).delete
        super
      end

      private

      def no_columns_selected?
        opts[:select].nil?
      end
    end
  end
end
