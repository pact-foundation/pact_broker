module PactBroker
  module Pacts
    module PactPublicationWipDatasetModule

      # Use a cut down model of the verifications table just for the WIP calculations.
      # Don't need all the associations and normal domain methods.
      class VerificationForWipCalculations < Sequel::Model(:verifications)
        dataset_module do
          def successful_non_wip_by_provider(provider_id)
            distinct.where(success: true, wip: false, provider_id: provider_id)
          end

          def verified_before_creation_date_of(record)
            if record
              verified_before_date(record.created_at)
            else
              self
            end
          end

          def join_branch_versions_excluding_branch(provider_id, branch_name)
            branch_versions_join = {
              Sequel[:verifications][:provider_version_id] => Sequel[:branch_versions][:version_id],
              Sequel[:branch_versions][:pacticipant_id] => provider_id
            }
            join(:branch_versions, branch_versions_join) do
              Sequel.lit("branch_versions.branch_name != ?", branch_name)
            end
          end

          def join_provider_versions_for_provider_id_and_branch(provider_id, provider_version_branch)
            branch_versions_join = {
              Sequel[:verifications][:provider_version_id] => Sequel[:branch_versions][:version_id],
              Sequel[:branch_versions][:pacticipant_id] => provider_id,
              Sequel[:branch_versions][:branch_name] => provider_version_branch
            }

            join(:branch_versions, branch_versions_join)
          end

          def verified_before_date(date)
            where { Sequel[:verifications][:execution_date] < date }
          end
        end
      end

      def successfully_verified_by_provider_branch_when_not_wip(provider_id, provider_version_branch)
        successful_verifications = VerificationForWipCalculations
                                     .select(:pact_version_id)
                                     .distinct
                                     .successful_non_wip_by_provider(provider_id)
                                     .join_provider_versions_for_provider_id_and_branch(provider_id, provider_version_branch)


        from_self(alias: :pp)
          .select(Sequel[:pp].*)
          .distinct
          .join(successful_verifications, { Sequel[:pp][:pact_version_id] => Sequel[:v][:pact_version_id] }, { table_alias: :v })
      end

      def successfully_verified_by_provider_another_branch_before_this_branch_first_created(provider_id, provider_version_branch)
        first_version_for_branch = PactBroker::Domain::Version.first_for_pacticipant_id_and_branch(provider_id, provider_version_branch)

        successful_verifications = VerificationForWipCalculations
                                     .select(:pact_version_id)
                                     .distinct
                                     .successful_non_wip_by_provider(provider_id)
                                     .join_branch_versions_excluding_branch(provider_id, provider_version_branch)
                                     .verified_before_creation_date_of(first_version_for_branch)

        from_self(alias: :pp)
          .select(Sequel[:pp].*)
          .join(successful_verifications, { Sequel[:pp][:pact_version_id] => Sequel[:v][:pact_version_id] }, { table_alias: :v })
      end

      def successfully_verified_by_provider_tag_when_not_wip(provider_tag)
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
    end
  end
end
