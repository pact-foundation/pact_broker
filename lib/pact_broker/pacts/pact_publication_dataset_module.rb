require "pact_broker/pacts/pact_publication_selector_dataset_module"
require "pact_broker/feature_toggle"

module PactBroker
  module Pacts
    # rubocop: disable Metrics/ModuleLength
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

      def untagged
        left_outer_join(:tags, { version_id: :consumer_version_id })
          .where(Sequel.qualify(:tags, :name) => nil)
      end

      def for_consumer_version_tag tag_name
        base_query = self
        if no_columns_selected?
          base_query = base_query.select_all_qualified.select_append(Sequel[:tags][:name].as(:tag_name))
        end

        base_query
          .join(:tags, { version_id: :consumer_version_id, Sequel[:tags][:name] => tag_name })
          .remove_overridden_revisions_from_complete_query
      end

      def for_consumer_version_tag_all_revisions tag_name
        join(:tags, { version_id: :consumer_version_id }) do
          name_like(Sequel[:tags][:name], tag_name)
        end
      end

      def for_consumer_name_and_maybe_version_number(consumer_name, consumer_version_number)
        if consumer_version_number
          where(consumer_version: PactBroker::Domain::Version.where_pacticipant_name_and_version_number(consumer_name, consumer_version_number))
        else
          where(consumer: PactBroker::Domain::Pacticipant.find_by_name(consumer_name))
        end
      end

      # Returns the latest pact for each branch, returning a pact for every branch, even if
      # the most recent version of that branch does not have a pact.
      # This is different from for_all_branch_heads, which will find the branch head versions,
      # and return the pacts associated with those versions.
      # This method should not be used for 'pacts for verification', because it will return
      # a pact for branches where that integration should no longer exist.
      # @return [Dataset<PactBroker::Pacts::PactPublication>]
      def latest_by_consumer_branch
        branch_versions_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:branch_versions][:version_id]
        }

        branches_join = {
          Sequel[:branch_versions][:branch_id] => Sequel[:branches][:id]
        }

        max_orders = join(:branch_versions, branch_versions_join)
                      .join(:branches, branches_join)
                      .select_group(Sequel[:pact_publications][:consumer_id], Sequel[:pact_publications][:provider_id], Sequel[:branches][:name].as(:branch_name))
                      .select_append{ max(consumer_version_order).as(latest_consumer_version_order) }

        max_join = {
          Sequel[:max_orders][:consumer_id] => Sequel[:pact_publications][:consumer_id],
          Sequel[:max_orders][:provider_id] => Sequel[:pact_publications][:provider_id],
          Sequel[:max_orders][:latest_consumer_version_order] => Sequel[:pact_publications][:consumer_version_order]
        }

        base_query = self
        if no_columns_selected?
          base_query = base_query.select_all_qualified.select_append(Sequel[:max_orders][:branch_name].as(:branch_name))
        end

        base_query
          .remove_overridden_revisions
          .join(max_orders, max_join, { table_alias: :max_orders })
      end

      def overall_latest
        self_join = {
          Sequel[:pact_publications][:consumer_id] => Sequel[:pp2][:consumer_id],
          Sequel[:pact_publications][:provider_id] => Sequel[:pp2][:provider_id],
          Sequel[:pact_publications][:consumer_version_order] => Sequel[:pp2][:max_consumer_version_order]
        }

        base_query = self
        base_query = base_query.select_all_qualified if no_columns_selected?

        base_query.join(
          base_query.select_group(:consumer_id, :provider_id).select_append{ max(:consumer_version_order).as(:max_consumer_version_order) },
          self_join,
          table_alias: :pp2
        )
        .remove_overridden_revisions_from_complete_query
      end

      def overall_latest_for_consumer_id_and_provider_id(consumer_id, provider_id)
        for_consumer_id_and_provider_id(consumer_id, provider_id)
          .order(Sequel.desc(Sequel[:pact_publications][:consumer_version_order]), Sequel.desc(:revision_number))
          .limit(1)
      end

      # Returns the pacts (if they exist) for all the branch heads.
      # If the version for the branch head does not have a pact, then no pact is returned,
      # (unlike latest_by_consumer_branch)
      # This is much more performant than latest_by_consumer_branch and should be used
      # for the 'pacts for verification' response
      # @return [Dataset<PactBroker::Pacts::PactPublication>]
      def for_all_branch_heads
        base_query = self
        base_query = base_query.join(:branch_heads, { Sequel[:bh][:version_id] => Sequel[:pact_publications][:consumer_version_id] }, { table_alias: :bh })

        if no_columns_selected?
          base_query = base_query.select_all_qualified.select_append(Sequel[:bh][:branch_name].as(:branch_name))
        end

        base_query.remove_overridden_revisions
      end

      # Return the pacts (if they exist) for the branch heads of the given branch names
      # This uses the new logic of finding the branch head and returning any associated pacts,
      # rather than the old logic of returning the pact for the latest version
      # on the branch that had a pact.
      # @param [String] branch_name
      # @return [Sequel::Dataset<PactBroker::Pacts::PactPublication>]
      def for_branch_heads(branch_name)
        branch_head_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:branch_heads][:version_id],
        }

        base_query = self
        if no_columns_selected?
          base_query = base_query.select_all_qualified.select_append(Sequel[:branch_heads][:branch_name].as(:branch_name))
        end

        base_query
          .join(:branch_heads, branch_head_join) do
            name_like(Sequel[:branch_heads][:branch_name], branch_name)
          end
          .remove_overridden_revisions_from_complete_query
      end

      # The pact that belongs to the branch head.
      # May return nil if the branch head does not have a pact published for it.
      def latest_for_consumer_branch(branch_name)
        for_branch_heads(branch_name)
      end

      # The latest pact that belongs to a version on the specified branch (might not be the version that is the branch head)
      # Always returns a pact, if any pacts exist for this branch.
      def old_latest_for_consumer_branch(branch_name)
        branch_versions_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:branch_versions][:version_id]
        }

        branches_join = {
          Sequel[:branch_versions][:branch_id] => Sequel[:branches][:id],
          Sequel[:branches][:name] => branch_name
        }

        max_orders = join(:branch_versions, branch_versions_join)
                      .join(:branches, branches_join)
                      .select_group(Sequel[:pact_publications][:consumer_id], Sequel[:pact_publications][:provider_id], Sequel[:branches][:name].as(:branch_name))
                      .select_append{ max(consumer_version_order).as(latest_consumer_version_order) }

        max_join = {
          Sequel[:max_orders][:consumer_id] => Sequel[:pact_publications][:consumer_id],
          Sequel[:max_orders][:provider_id] => Sequel[:pact_publications][:provider_id],
          Sequel[:max_orders][:latest_consumer_version_order] => Sequel[:pact_publications][:consumer_version_order]
        }

        base_query = self
        if no_columns_selected?
          base_query = base_query.select_all_qualified.select_append(Sequel[:max_orders][:branch_name].as(:branch_name))
        end
        base_query
          .join(max_orders, max_join, { table_alias: :max_orders })
          .remove_overridden_revisions_from_complete_query
      end

      # The latest pact publication for each tag
      # This uses the old logic of "the latest pact for a version that has a tag" (which always returns a pact)
      # rather than "the pact for the latest version with a tag"
      #
      # For 'pacts for verification' this has been replaced by for_all_tag_heads
      # This should only be used for the UI
      # @return [Sequel::Dataset<PactBroker::Pacts::PactPublication>]
      def latest_by_consumer_tag
        tags_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:tags][:version_id],
        }

        max_orders = join(:tags, tags_join)
                      .select_group(:consumer_id, :provider_id, Sequel[:tags][:name].as(:tag_name))
                      .select_append{ max(consumer_version_order).as(latest_consumer_version_order) }

        max_join = {
          Sequel[:max_orders][:consumer_id] => Sequel[:pact_publications][:consumer_id],
          Sequel[:max_orders][:provider_id] => Sequel[:pact_publications][:provider_id],
          Sequel[:max_orders][:latest_consumer_version_order] => Sequel[:pact_publications][:consumer_version_order]
        }

        base_query = self
        if no_columns_selected?
          base_query = base_query.select_all_qualified.select_append(Sequel[:max_orders][:tag_name])
        end

        base_query
          .join(max_orders, max_join, { table_alias: :max_orders })
          .remove_overridden_revisions_from_complete_query
      end

      # This uses the old logic of "the latest pact for a version that has a tag" (which always returns a pact)
      # rather than "the pact for the latest version with a tag"
      # Need to see about updating this.
      # @return [Sequel::Dataset<PactBroker::Pacts::PactPublication>]
      def latest_for_consumer_tag(tag_name)
        tags_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:tags][:version_id],
          Sequel[:tags][:name] => tag_name
        }

        max_orders = join(:tags, tags_join)
                      .select_group(:consumer_id, :provider_id, Sequel[:tags][:name].as(:tag_name))
                      .select_append{ max(consumer_version_order).as(latest_consumer_version_order) }


        max_join = {
          Sequel[:max_orders][:consumer_id] => Sequel[:pact_publications][:consumer_id],
          Sequel[:max_orders][:provider_id] => Sequel[:pact_publications][:provider_id],
          Sequel[:max_orders][:latest_consumer_version_order] => Sequel[:pact_publications][:consumer_version_order]
        }

        base_query = self
        if no_columns_selected?
          base_query = base_query.select_all_qualified.select_append(Sequel[:max_orders][:tag_name])
        end

        base_query
          .join(max_orders, max_join, { table_alias: :max_orders })
          .remove_overridden_revisions_from_complete_query
      end

      # The pacts for the latest versions with the specified tag (new logic)
      # NOT the latest pact that belongs to a version with the specified tag.
      def for_latest_consumer_versions_with_tag(tag_name)
        head_tags = PactBroker::Domain::Tag
                      .select_group(:pacticipant_id, :name)
                      .select_append{ max(version_order).as(:latest_version_order) }
                      .where(name: tag_name)

        head_tags_join = {
          Sequel[:pact_publications][:consumer_id] => Sequel[:head_tags][:pacticipant_id],
          Sequel[:pact_publications][:consumer_version_order] => Sequel[:head_tags][:latest_version_order]
        }

        base_query = self
        if no_columns_selected?
          base_query = base_query.select_all_qualified.select_append(Sequel[:head_tags][:name].as(:tag_name))
        end

        base_query
          .join(head_tags, head_tags_join, { table_alias: :head_tags })
         .remove_overridden_revisions_from_complete_query
      end

      # The pacts for the latest versions for each tag.
      # Will not return a pact if the pact is no longer published for a particular tag
      # NEW LOGIC
      # @return [Sequel::Dataset<PactBroker::Pacts::PactPublication>]
      def for_all_tag_heads
        head_tags = PactBroker::Domain::Tag
                      .select_group(:pacticipant_id, :name)
                      .select_append{ max(version_order).as(:latest_version_order) }

        head_tags_join = {
          Sequel[:pact_publications][:consumer_id] => Sequel[:head_tags][:pacticipant_id],
          Sequel[:pact_publications][:consumer_version_order] => Sequel[:head_tags][:latest_version_order]
        }

        base_query = self
        if no_columns_selected?
          base_query = base_query.select_all_qualified.select_append(Sequel[:head_tags][:name].as(:tag_name))
        end

        base_query
          .join(head_tags, head_tags_join, { table_alias: :head_tags })
         .remove_overridden_revisions_from_complete_query
      end

      def in_environments
        currently_deployed_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:currently_deployed_version_ids][:version_id]
        }

        released_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:released_versions][:version_id],
          Sequel[:released_versions][:support_ended_at] => nil
        }

        base_query = self
        if no_columns_selected?
          base_query = base_query.select_all_qualified
        end

        deployed = base_query.join(:currently_deployed_version_ids, currently_deployed_join)
        released = base_query.join(:released_versions, released_join)

        deployed.union(released).remove_overridden_revisions_from_complete_query
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

      def join_consumer_branch_versions
        join(:branch_versions, { Sequel[:pact_publications][:consumer_version_id] => Sequel[:branch_versions][:version_id] })
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

      def for_branch_name branch_name
        branch_versions_join = {
          Sequel[:branch_versions][:version_id] => Sequel[:pact_publications][:consumer_version_id],
          Sequel[:branch_versions][:branch_name] => branch_name
        }

        base_query = self
        if no_columns_selected?
          base_query = base_query.select_all_qualified.select_append(Sequel[:branch_versions][:branch_name].as(:branch_name))
        end

        base_query.join(:branch_versions, branch_versions_join)
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
        where(name_like(Sequel[:ct][:name],tag))
      end

      def consumer_version_order_before order
        where(Sequel.lit("consumer_version_order < ?", order))
      end

      def consumer_version_order_after order
        where(Sequel.lit("consumer_version_order > ?", order))
      end

      def latest_by_consumer_version_order
        reverse_order(:consumer_version_order).limit(1)
      end

      def order_by_consumer_name
        order_append_ignore_case(Sequel[:consumers][:name])
      end

      def order_by_consumer_version_order
        order_append(:consumer_version_order, :revision_number)
      end

      def earliest
        order(:consumer_version_order).limit(1)
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
    # rubocop: enable Metrics/ModuleLength
  end
end
