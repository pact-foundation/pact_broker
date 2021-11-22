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
        first_version_for_branch = PactBroker::Domain::Version.first_for_pacticipant_id_and_branch(provider_id, provider_version_branch)

        from_self(alias: :pp)
          .select(Sequel[:pp].*)
          .join_successful_non_wip_verifications_for_provider_id(provider_id)
          .join_provider_versions_for_provider_id(provider_id)
          .join_branch_versions_excluding_branch(provider_version_branch)
          .where(Sequel[:pp][:provider_id] => provider_id)
          .verified_before_creation_date_of(first_version_for_branch)
          .distinct
      end

      def join_branch_versions_excluding_branch(branch_name)
        branch_versions_join = {
          Sequel[:provider_versions][:id] => Sequel[:branch_versions][:version_id]
        }
        join(:branch_versions, branch_versions_join) do
          Sequel.lit("branch_versions.branch_name != ?", branch_name)
        end
      end

      def successfully_verified_by_provider_tag_when_not_wip(provider_id, provider_tag)
        return new_successfully_verified_by_provider_tag_when_not_wip(provider_id, provider_tag) if PactBroker.feature_enabled?(:new_wip_calculation)

        from_self(alias: :pp)
          .select(Sequel[:pp].*)
          .where(Sequel[:pp][:provider_id] => provider_id)
          .join_successful_non_wip_verifications_for_provider_id(provider_id)
          .join_provider_version_tags_for_tag(provider_tag)
          .distinct
      end

      def new_successfully_verified_by_provider_tag_when_not_wip(provider_id, provider_tag)
        pact_version_provider_tag_verifications_join = {
          Sequel[:sv][:pact_version_id] => Sequel[:pp][:pact_version_id],
          Sequel[:sv][:provider_version_tag_name] => provider_tag,
          Sequel[:sv][:wip] => false
        }

        from_self(alias: :pp)
          .select(Sequel[:pp].*)
          .join(:pact_version_provider_tag_successful_verifications, pact_version_provider_tag_verifications_join, { table_alias: :sv })
          .distinct

      end

      def successfully_verified_by_provider_another_tag_before_this_tag_first_created(provider_id, provider_tag)
        return new_successfully_verified_by_provider_another_tag_before_this_tag_first_created(provider_id, provider_tag) if PactBroker.feature_enabled?(:new_wip_calculation)

        first_tag_with_name = PactBroker::Domain::Tag.where(pacticipant_id: provider_id, name: provider_tag).order(:created_at).first
        from_self(alias: :pp)
          .select(Sequel[:pp].*)
          .where(Sequel[:pp][:provider_id] => provider_id)
          .join_successful_non_wip_verifications_for_provider_id(provider_id)
          .join_provider_version_tags do
            Sequel.lit("provider_tags.name != ?", provider_tag)
          end
          .verified_before_creation_date_of(first_tag_with_name)
          .distinct
      end

      def new_successfully_verified_by_provider_another_tag_before_this_tag_first_created(provider_id, provider_tag)
        first_tag_with_name = PactBroker::Domain::Tag.where(pacticipant_id: provider_id, name: provider_tag).order(:created_at).first

        pact_version_provider_tag_verifications_join = {
          Sequel[:sv][:pact_version_id] => Sequel[:pp][:pact_version_id],
          Sequel[:sv][:wip] => false
        }

        created_at_criteria = if first_tag_with_name
                                Sequel.lit("sv.execution_date < ?", first_tag_with_name.created_at)
                              else
                                Sequel.lit("1 = 1")
                              end

        from_self(alias: :pp)
          .select(Sequel[:pp].*)
          .where(Sequel[:pp][:provider_id] => provider_id)
          .join(:pact_version_provider_tag_successful_verifications, pact_version_provider_tag_verifications_join, { table_alias: :sv }) do
            Sequel.&(
              Sequel.lit("sv.provider_version_tag_name NOT IN (?)", provider_tag),
              created_at_criteria
            )
          end
          .distinct
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
          Sequel[:provider_versions][:pacticipant_id] => provider_id
        }
        branch_versions_join = {
          Sequel[:provider_versions][:id] => Sequel[:branch_versions][:version_id],
          Sequel[:branch_versions][:branch_name] => provider_version_branch
        }
        join(:versions, versions_join, { table_alias: :provider_versions } )
          .join(:branch_versions, branch_versions_join)
      end

      def join_provider_versions_for_provider_id(provider_id, &block)
        versions_join = {
          Sequel[:verifications][:provider_version_id] => Sequel[:provider_versions][:id],
          Sequel[:provider_versions][:pacticipant_id] => provider_id
        }
        join(:versions, versions_join, { table_alias: :provider_versions }, &block)
      end

      def verified_before_creation_date_of(record)
        if record
          verified_before_date(record.created_at)
        else
          self
        end
      end
    end
  end
end
