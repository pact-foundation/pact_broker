require "pact_broker/matrix/matrix_row"

# Same as PactBroker::Matrix::MatrixRow
# except the data is sourced from the pact_publications table, and contains
# every pact publication, not just the latest publication for the consumer version.
# This is used when there is no "latestby" in the matrix query.
module PactBroker
  module Matrix
    class EveryRow < PactBroker::Matrix::MatrixRow
      set_dataset(Sequel.as(:pact_publications, :p))

      # Same as PactBroker::Matrix::MatrixRow::Verification
      # except the data is sourced from the verifications table, and contains
      # every verification, not just the latest verification for the pact version and the provider version.
      # This is used when there is no "latestby" in the matrix query.
      class Verification < PactBroker::Matrix::MatrixRow::Verification
        set_dataset(:verifications)

        dataset_module do
          # @override the definition from PactBroker::Matrix::MatrixRow::Verification, with the equivalent column names from the
          # verifications table.
          select(:select_verification_columns,
            Sequel[:verifications][:id].as(:verification_id),
            Sequel[:verifications][:provider_version_id],
            Sequel[:verifications][:created_at].as(:provider_version_created_at),
            Sequel[:verifications][:pact_version_id]
          )

          # @override the definition from PactBroker::Matrix::MatrixRow::Verification, with the equivalent column names from the
          # verifications table.
          select(:select_verification_columns_2,
            Sequel[:verifications][:id],
            Sequel[:verifications][:provider_version_id],
            Sequel[:verifications][:created_at],
            Sequel[:verifications][:pact_version_id]
          )
        end
      end

      P_V_JOIN = { Sequel[:p][:pact_version_id] => Sequel[:v][:pact_version_id] }

      PACT_COLUMNS = [
        Sequel[:p][:consumer_id],
        Sequel[:p][:provider_id],
        Sequel[:p][:consumer_version_id],
        Sequel[:p][:id].as(:pact_publication_id),
        Sequel[:p][:pact_version_id],
        Sequel[:p][:revision_number].as(:pact_revision_number),
        Sequel[:p][:created_at].as(:consumer_version_created_at),
        Sequel[:p][:id].as(:pact_order)
      ]

      VERIFICATION_COLUMNS = [
        Sequel[:v][:id].as(:verification_id),
        Sequel[:v][:provider_version_id],
        Sequel[:v][:created_at].as(:provider_version_created_at)
      ]

      dataset_module do
        select(:select_all_columns, *PACT_COLUMNS, *VERIFICATION_COLUMNS)
        select(:select_pact_columns, *PACT_COLUMNS)

        def left_outer_join_verifications
          left_outer_join(:verifications, P_V_JOIN, { table_alias: :v } )
        end

        def verification_model
          EveryRow::Verification
        end
      end
    end
  end
end
