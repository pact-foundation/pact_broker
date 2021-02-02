module PactBroker
  module Pacts
    module PactPublicationDatasetModule
      def for_provider provider
        where(provider: provider)
      end

      def for_consumer consumer
        where(consumer: consumer)
      end

      def for_provider_and_consumer_version_selector provider, selector
        # Does not yet support "all pacts for specified tag" - that code is still in the Pact::Repository
        query = for_provider(provider)
        query = query.for_consumer(PactBroker::Domain::Pacticipant.find_by_name(selector.consumer)) if selector.consumer
        # Do this last so that the provider/consumer criteria get included in the "latest" query before the join, rather than after
        query = query.latest_for_consumer_branch(selector.branch) if selector.latest_for_branch?
        query = query.latest_for_consumer_tag(selector.tag) if selector.latest_for_tag?
        query = query.overall_latest if selector.overall_latest?
        query
      end

      def latest_by_consumer_branch
        versions_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:cv][:id]
        }

        base_query = select_all_qualified
          .select_append(Sequel[:cv][:branch], Sequel[:cv][:order])
          .remove_overridden_revisions
          .join(:versions, versions_join, { table_alias: :cv }) do
            Sequel.lit("cv.branch is not null")
          end

        self_join = {
          Sequel[:pact_publications][:consumer_id] => Sequel[:pp2][:consumer_id],
          Sequel[:cv][:branch] => Sequel[:pp2][:branch]
        }

        base_query.left_join(base_query, self_join, { table_alias: :pp2 } ) do
          Sequel[:pp2][:order] > Sequel[:cv][:order]
        end
        .where(Sequel[:pp2][:order] => nil)
      end

      def overall_latest
        base_query = select_all_qualified
          .select_append(Sequel[:cv][:order])
          .remove_overridden_revisions
          .join_consumer_versions # won't need to do this when we add the order to latest_pact_publication_ids_for_consumer_versions

        self_join = {
          Sequel[:pact_publications][:consumer_id] => Sequel[:pp2][:consumer_id],
          Sequel[:pact_publications][:provider_id] => Sequel[:pp2][:provider_id]
        }

        base_query.left_join(base_query, self_join, { table_alias: :pp2 } ) do
          Sequel[:pp2][:order] > Sequel[:cv][:order]
        end
        .where(Sequel[:pp2][:order] => nil)
      end

      def latest_for_consumer_branch(branch)
        versions_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:cv][:id],
          Sequel[:cv][:branch] => branch
        }

        base_query = select_all_qualified
          .select_append(Sequel[:cv][:branch], Sequel[:cv][:order])
          .remove_overridden_revisions
          .join(:versions, versions_join, { table_alias: :cv }) do
            Sequel.lit("cv.branch is not null")
          end

        self_join = {
          Sequel[:pact_publications][:consumer_id] => Sequel[:pp2][:consumer_id],
          Sequel[:cv][:branch] => Sequel[:pp2][:branch]
        }

        base_query.left_join(base_query, self_join, { table_alias: :pp2 } ) do
          Sequel[:pp2][:order] > Sequel[:cv][:order]
        end
        .where(Sequel[:pp2][:order] => nil)
      end

      def latest_by_consumer_tag
        versions_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:cv][:id]
        }

        tags_join = {
          Sequel[:cv][:id] => Sequel[:tags][:version_id]
        }

        base_query = select_all_qualified
          .select_append(Sequel[:cv][:order], Sequel[:tags][:name].as(:tag_name))
          .remove_overridden_revisions
          .join(:versions, versions_join, { table_alias: :cv })
          .join(:tags, tags_join)

        self_join = {
          Sequel[:pact_publications][:consumer_id] => Sequel[:pp2][:consumer_id],
          Sequel[:tags][:name] => Sequel[:pp2][:tag_name]
        }
        base_query.left_join(base_query, self_join, { table_alias: :pp2 } ) do
          Sequel[:pp2][:order] > Sequel[:cv][:order]
        end
        .where(Sequel[:pp2][:order] => nil)
      end

      def latest_for_consumer_tag(tag_name)
        versions_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:cv][:id]
        }

        tags_join = {
          Sequel[:cv][:id] => Sequel[:tags][:version_id],
          Sequel[:tags][:name] => tag_name
        }

        base_query = select_all_qualified
          .select_append(Sequel[:cv][:order], Sequel[:tags][:name].as(:tag_name))
          .remove_overridden_revisions
          .join(:versions, versions_join, { table_alias: :cv })
          .join(:tags, tags_join)
          .where(Sequel[:tags][:name] => tag_name)

        self_join = {
          Sequel[:pact_publications][:consumer_id] => Sequel[:pp2][:consumer_id],
          Sequel[:tags][:name] => Sequel[:pp2][:tag_name]
        }
        base_query.left_join(base_query, self_join, { table_alias: :pp2 } ) do
          Sequel[:pp2][:order] > Sequel[:cv][:order]
        end
        .where(Sequel[:pp2][:order] => nil)
      end

      def successfully_verified_by_provider_branch(provider_id, provider_version_branch)
        verifications_join = {
          pact_version_id: :pact_version_id,
          Sequel[:verifications][:success] => true,
          Sequel[:verifications][:wip] => false,
          Sequel[:verifications][:provider_id] => provider_id
        }
        versions_join = {
          Sequel[:verifications][:provider_version_id] => Sequel[:provider_versions][:id],
          Sequel[:provider_versions][:branch] => provider_version_branch,
          Sequel[:provider_versions][:pacticipant_id] => provider_id
        }

        from_self(alias: :pp).select(Sequel[:pp].*)
          .join(:verifications, verifications_join)
          .join(:versions, versions_join, { table_alias: :provider_versions } )
          .where(Sequel[:pp][:provider_id] => provider_id)
          .distinct
      end

      def successfully_verified_by_provider_tag(provider_id, provider_tag)
        verifications_join = {
          pact_version_id: :pact_version_id,
          Sequel[:verifications][:success] => true,
          Sequel[:verifications][:wip] => false,
          Sequel[:verifications][:provider_id] => provider_id
        }
        tags_join = {
          Sequel[:verifications][:provider_version_id] => Sequel[:provider_tags][:version_id],
          Sequel[:provider_tags][:name] => provider_tag
        }

        from_self(alias: :pp).select(Sequel[:pp].*)
          .join(:verifications, verifications_join)
          .join(:tags, tags_join, { table_alias: :provider_tags } )
          .where(Sequel[:pp][:provider_id] => provider_id)
          .distinct
      end

      def created_after date
        where(Sequel.lit("#{first_source_alias}.created_at > ?", date))
      end

      def remove_overridden_revisions
        join(:latest_pact_publication_ids_for_consumer_versions, { Sequel[:lp][:pact_publication_id] => Sequel[:pact_publications][:id] }, { table_alias: :lp})
      end

      def join_consumer_versions(table_alias = :cv)
        join(:versions, { Sequel[:pact_publications][:consumer_version_id] => Sequel[table_alias][:id] }, { table_alias: table_alias })
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

      def join_providers(table_alias = :providers)
        join(:pacticipants, { Sequel[:pact_publications][:provider_id] => Sequel[table_alias][:id] }, { table_alias: table_alias })
      end

      def join_consumers(table_alias = :consumers)
        join(:pacticipants, { Sequel[:pact_publications][:consumer_id] => Sequel[table_alias][:id] }, { table_alias: table_alias })
      end

      def join_pact_versions
        join(:pact_versions, { Sequel[:pact_publications][:pact_version_id] => Sequel[:pact_versions][:id] })
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
        order_append(Sequel[:cv][:order])
      end

      def where_consumer_if_set(consumer)
        if consumer
          where(consumer: consumer)
        else
          self
        end
      end

      def delete
        require 'pact_broker/webhooks/triggered_webhook'
        PactBroker::Webhooks::TriggeredWebhook.where(pact_publication: self).delete
        super
      end
    end
  end
end
