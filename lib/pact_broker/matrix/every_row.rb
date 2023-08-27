require "pact_broker/matrix/matrix_row"
require "pact_broker/matrix/matrix_row_dataset_module"
require "pact_broker/matrix/matrix_row_instance_methods"

# Same as PactBroker::Matrix::MatrixRow
# except the data is sourced from the pact_publications table, and contains
# every pact publication, not just the latest publication for the consumer version.
# This is used when there is no "latestby" in the matrix query.
module PactBroker
  module Matrix
    class EveryRow < Sequel::Model(Sequel.as(:pact_publications, :p))

      # Must be kept in sync with PactBroker::Matrix::MatrixRow
      associate(:many_to_one, :pact_publication, :class => "PactBroker::Pacts::PactPublication", :key => :pact_publication_id, :primary_key => :id)
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:many_to_one, :consumer, :class => "PactBroker::Domain::Pacticipant", :key => :consumer_id, :primary_key => :id)
      associate(:many_to_one, :consumer_version, :class => "PactBroker::Domain::Version", :key => :consumer_version_id, :primary_key => :id)
      associate(:many_to_one, :provider_version, :class => "PactBroker::Domain::Version", :key => :provider_version_id, :primary_key => :id)
      associate(:many_to_one, :pact_version, class: "PactBroker::Pacts::PactVersion", :key => :pact_version_id, :primary_key => :id)
      associate(:many_to_one, :verification, class: "PactBroker::Domain::Verification", :key => :verification_id, :primary_key => :id)
      associate(:one_to_many, :consumer_version_tags, :class => "PactBroker::Tags::TagWithLatestFlag", primary_key: :consumer_version_id, key: :version_id)
      associate(:one_to_many, :provider_version_tags, :class => "PactBroker::Tags::TagWithLatestFlag", primary_key: :provider_version_id, key: :version_id)

      # Same as PactBroker::Matrix::MatrixRow::Verification
      # except the data is sourced from the verifications table, and contains
      # every verification, not just the latest verification for the pact version and the provider version.
      # This is used when there is no "latestby" in the matrix query.
      class Verification < PactBroker::Matrix::MatrixRow::Verification
        set_dataset(:verifications)

        dataset_module do
          select(:select_verification_columns_with_aliases,
            Sequel[:verifications][:id].as(:verification_id),
            Sequel[:verifications][:provider_version_id],
            Sequel[:verifications][:created_at].as(:provider_version_created_at),
            Sequel[:verifications][:pact_version_id]
          )
        end
      end

      PACT_COLUMNS_WITH_ALIASES = [
        Sequel[:p][:consumer_id],
        Sequel[:p][:provider_id],
        Sequel[:p][:consumer_version_id],
        Sequel[:p][:id].as(:pact_publication_id),
        Sequel[:p][:pact_version_id],
        Sequel[:p][:revision_number].as(:pact_revision_number),
        Sequel[:p][:created_at].as(:consumer_version_created_at),
        Sequel[:p][:id].as(:pact_order)
      ]

      ALL_COLUMNS_AFTER_JOIN = [
        Sequel[:p][:consumer_id],
        Sequel[:p][:provider_id],
        Sequel[:p][:consumer_version_id],
        Sequel[:p][:pact_publication_id],
        Sequel[:p][:pact_version_id],
        Sequel[:p][:pact_revision_number],
        Sequel[:p][:consumer_version_created_at],
        Sequel[:p][:pact_order],
        Sequel[:v][:verification_id],
        Sequel[:v][:provider_version_id],
        Sequel[:v][:provider_version_created_at]
      ]

      dataset_module do
        include PactBroker::Matrix::MatrixRowDatasetModule

        select(:select_pact_columns_with_aliases, *PACT_COLUMNS_WITH_ALIASES)
        select(:select_all_columns_after_join, *ALL_COLUMNS_AFTER_JOIN)

        def verification_model
          EveryRow::Verification
        end
      end

      def pact_publication_id
        return_or_raise_if_not_set(:pact_publication_id)
      end

      include PactBroker::Matrix::MatrixRowInstanceMethods
    end
  end
end
