module PactBroker
  module Pacts
    module PactPublicationWipDatasetModule
      def successfully_verified_by_provider_branch_when_not_wip(provider_id, provider_version_branch)
        from_self(alias: :pp)
          .select(Sequel[:pp].*)
          .where(Sequel[:pp][:provider_id] => provider_id)
          .join_successful_non_wip_verifications_for_provider_id(provider_id)
          .join_provider_versions_for_provider_id_and_branch(provider_id, provider_version_branch)
          .distinct
      end

      def successfully_verified_by_provider_another_branch_before_this_branch_first_created(provider_id, provider_version_branch)
        query = from_self(alias: :pp)
          .select(Sequel[:pp].*)
          .join_successful_non_wip_verifications_for_provider_id(provider_id)
          .join_provider_versions_for_provider_id(provider_id) do
            Sequel.lit('provider_versions.branch != ?', provider_version_branch)
          end
          .where(Sequel[:pp][:provider_id] => provider_id)

        first_version_for_branch = PactBroker::Domain::Version.first_for_pacticipant_id_and_branch(provider_id, provider_version_branch)
        query = query.verified_before_date(first_version_for_branch.created_at) if first_version_for_branch
        query.distinct
      end

      def successfully_verified_by_provider_tag_when_not_wip(provider_id, provider_tag)
        from_self(alias: :pp).select(Sequel[:pp].*)
          .join_successful_non_wip_verifications_for_provider_id(provider_id)
          .join_provider_version_tags_for_tag(provider_tag)
          .where(Sequel[:pp][:provider_id] => provider_id)
          .distinct
      end

      def successfully_verified_by_provider_another_tag_before_this_tag_first_created(provider_id, provider_tag)
        query = from_self(alias: :pp)
          .select(Sequel[:pp].*)
          .where(Sequel[:pp][:provider_id] => provider_id)
          .join_successful_non_wip_verifications_for_provider_id(provider_id)
          .join_provider_version_tags do
            Sequel.lit('provider_tags.name != ?', provider_tag)
          end

        first_tag_with_name = PactBroker::Domain::Tag.where(pacticipant_id: provider_id, name: provider_tag).order(:created_at).first
        query = query.verified_before_date(first_tag_with_name.created_at) if first_tag_with_name
        query.distinct
      end

      protected

      def verified_before_date(date)
        where { Sequel[:verifications][:execution_date] < date }
      end

      def join_successful_non_wip_verifications_for_provider_id(provider_id, &block)
        verifications_join = {
          pact_version_id: :pact_version_id,
          Sequel[:verifications][:success] => true,
          Sequel[:verifications][:wip] => false,
          Sequel[:verifications][:provider_id] => provider_id
        }
        join(:verifications, verifications_join, {}, &block)
      end

      def join_provider_version_tags &block
        tags_join = {
          Sequel[:verifications][:provider_version_id] => Sequel[:provider_tags][:version_id],
        }
        join(:tags, tags_join, { table_alias: :provider_tags }, &block)
      end

      def join_provider_version_tags_for_tag(tag)
        tags_join = {
          Sequel[:verifications][:provider_version_id] => Sequel[:provider_tags][:version_id],
          Sequel[:provider_tags][:name] => tag
        }
        join(:tags, tags_join, { table_alias: :provider_tags } )
      end

      def join_provider_versions_for_provider_id_and_branch(provider_id, provider_version_branch)
        versions_join = {
          Sequel[:verifications][:provider_version_id] => Sequel[:provider_versions][:id],
          Sequel[:provider_versions][:branch] => provider_version_branch,
          Sequel[:provider_versions][:pacticipant_id] => provider_id
        }
        join(:versions, versions_join, { table_alias: :provider_versions } )
      end

      def join_provider_versions_for_provider_id(provider_id, &block)
        versions_join = {
          Sequel[:verifications][:provider_version_id] => Sequel[:provider_versions][:id],
          Sequel[:provider_versions][:pacticipant_id] => provider_id
        }
        join(:versions, versions_join, { table_alias: :provider_versions }, &block)
      end
    end
  end
end
