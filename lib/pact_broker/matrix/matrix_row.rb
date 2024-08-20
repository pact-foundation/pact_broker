require "pact_broker/dataset"
require "pact_broker/logging"
require "pact_broker/pacts/pact_version"
require "pact_broker/domain/pacticipant"
require "pact_broker/domain/version"
require "pact_broker/domain/verification"
require "pact_broker/domain/tag"
require "pact_broker/pacts/pact_publication"
require "pact_broker/matrix/matrix_row_dataset_module"
require "pact_broker/matrix/matrix_row_instance_methods"
require "pact_broker/matrix/matrix_row_verification_dataset_module"

# The PactBroker::Matrix::MatrixRow represents a row in the table that is created when
# the consumer versions are joined to the provider versions via the pacts and verifications tables,
# aka "The Matrix". The difference between this class and the EveryRow class is that
# the EveryRow class includes results for overridden pact verisons and verifications (used only when there is no latestby
# set in the matrix query), where as the MatrixRow class only includes the latest pact for each consumer version,
# and the latest verification for each provider version.

module PactBroker
  module Matrix
    class MatrixRow < Sequel::Model(Sequel.as(:latest_pact_publication_ids_for_consumer_versions, :p))

      class Verification < Sequel::Model(Sequel.as(:latest_verification_id_for_pact_version_and_provider_version, :v))
        dataset_module do
          select(:select_verification_columns_with_aliases,
            Sequel[:v][:provider_version_id],
            Sequel[:v][:verification_id],
            Sequel[:v][:created_at].as(:provider_version_created_at),
            Sequel[:v][:pact_version_id]
          )

          include PactBroker::Matrix::MatrixRowVerificationDatasetModule
        end
      end

      PACT_COLUMNS_WITH_ALIASES = [
        Sequel[:p][:consumer_id],
        Sequel[:p][:provider_id],
        Sequel[:p][:consumer_version_id],
        Sequel[:p][:pact_publication_id],
        Sequel[:p][:pact_version_id],
        Sequel[:p][:created_at].as(:consumer_version_created_at),
        Sequel[:p][:pact_publication_id].as(:pact_order)
      ]

      ALL_COLUMNS_AFTER_JOIN = [
        Sequel[:p][:consumer_id],
        Sequel[:p][:provider_id],
        Sequel[:p][:consumer_version_id],
        Sequel[:p][:pact_publication_id],
        Sequel[:p][:pact_version_id],
        Sequel[:p][:consumer_version_created_at],
        Sequel[:p][:pact_order],
        Sequel[:v][:verification_id],
        Sequel[:v][:provider_version_id],
        Sequel[:v][:provider_version_created_at]
      ]

      # Must be kept in sync with PactBroker::Matrix::EveryRow
      associate(:many_to_one, :pact_publication, :class => "PactBroker::Pacts::PactPublication", :key => :pact_publication_id, :primary_key => :id)
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:many_to_one, :consumer, :class => "PactBroker::Domain::Pacticipant", :key => :consumer_id, :primary_key => :id)
      associate(:many_to_one, :consumer_version, :class => "PactBroker::Domain::Version", :key => :consumer_version_id, :primary_key => :id)
      associate(:many_to_one, :provider_version, :class => "PactBroker::Domain::Version", :key => :provider_version_id, :primary_key => :id)
      associate(:many_to_one, :pact_version, class: "PactBroker::Pacts::PactVersion", :key => :pact_version_id, :primary_key => :id)
      associate(:many_to_one, :verification, class: "PactBroker::Domain::Verification", :key => :verification_id, :primary_key => :id)
      associate(:one_to_many, :consumer_version_tags, :class => "PactBroker::Domain::Tag", primary_key: :consumer_version_id, key: :version_id)
      associate(:one_to_many, :provider_version_tags, :class => "PactBroker::Domain::Tag", primary_key: :provider_version_id, key: :version_id)

      dataset_module do
        include PactBroker::Dataset
        include PactBroker::Matrix::MatrixRowDatasetModule

        select(:select_pact_columns_with_aliases, *PACT_COLUMNS_WITH_ALIASES)
        select(:select_all_columns_after_join, *ALL_COLUMNS_AFTER_JOIN)

        # @private
        def verification_dataset
          MatrixRow::Verification
        end
      end

      include PactBroker::Matrix::MatrixRowInstanceMethods
    end
  end
end
