require 'pact_broker/matrix/row'

module PactBroker
  module Matrix
    # A row for each of the overall latest pacts, and a row for each of the latest tagged pacts
    # Rows with a nil consumer_tag_name are the overall latest
    class HeadRow < Row
      set_dataset(:materialized_head_matrix)

      # one_to_one :latest_verification_for_consumer_version_tag,
      #   :class => "PactBroker::Verifications::LatestVerificationForConsumerVersionTag",
      #   primary_key: [:provider_id, :consumer_id, :consumer_version_tag_name], key: [:provider_id, :consumer_id, :consumer_version_tag_name]

      # Loading the latest_verification_for_consumer_version_tag objects this way is quicker than
      # doing it using an inbult relation with primary_key/key, if we are loading the relation for
      # the entire HeadRow table
      # Using the inbuilt relation puts constraints on the columns that are not necessary and slow
      # the query down.
      # This relation relies on consumer_version_tags already being loaded
      one_to_one :latest_verification_for_consumer_version_tag, :class => "PactBroker::Verifications::LatestVerificationForConsumerVersionTag", primary_keys: [], key: [], :eager_loader=>(proc do |eo_opts|
        tag_to_row = eo_opts[:rows].each_with_object({}) { | row, map | map[[row.provider_id, row.consumer_id, row.consumer_version_tag_name]] = row }
        eo_opts[:rows].each{|row| row.associations[:latest_verification_for_consumer_version_tag] = nil}

        # Need the all then the each to ensure the eager loading works
        PactBroker::Verifications::LatestVerificationForConsumerVersionTag.each do | verification |
          key = [verification.provider_id, verification.consumer_id, verification.consumer_version_tag_name]
          if tag_to_row[key]
            tag_to_row[key].associations[:latest_verification_for_consumer_version_tag] = verification
          end
        end
      end)

      dataset_module do
        include PactBroker::Repositories::Helpers
        include PactBroker::Logging

        def refresh ids
          return super unless ids[:tag_name]

          logger.debug("Refreshing #{model.table_name} for #{ids}")
          db = model.db
          table_name = model.table_name
          criteria = { consumer_id: ids[:pacticipant_id], consumer_version_tag_name: ids[:tag_name] }
          db.transaction do
            db[table_name].where(criteria).delete
            new_rows = db[source_view_name].where(criteria)
            db[table_name].insert(new_rows)
          end
        end
      end
    end
  end
end

# Table: materialized_head_matrix
# Columns:
#  consumer_id               | integer                     | NOT NULL
#  consumer_name             | text                        | NOT NULL
#  consumer_version_id       | integer                     | NOT NULL
#  consumer_version_number   | text                        | NOT NULL
#  consumer_version_order    | integer                     | NOT NULL
#  pact_publication_id       | integer                     | NOT NULL
#  pact_version_id           | integer                     | NOT NULL
#  pact_version_sha          | text                        | NOT NULL
#  pact_revision_number      | integer                     | NOT NULL
#  pact_created_at           | timestamp without time zone | NOT NULL
#  provider_id               | integer                     | NOT NULL
#  provider_name             | text                        | NOT NULL
#  provider_version_id       | integer                     |
#  provider_version_number   | text                        |
#  provider_version_order    | integer                     |
#  verification_id           | integer                     |
#  success                   | boolean                     |
#  verification_number       | integer                     |
#  verification_executed_at  | timestamp without time zone |
#  verification_build_url    | text                        |
#  consumer_version_tag_name | text                        |
# Indexes:
#  materialized_head_matrix_consumer_version_tag_name_index | btree (consumer_version_tag_name)
#  ndx_mhm_consumer_id                                      | btree (consumer_id)
#  ndx_mhm_cv_ord                                           | btree (consumer_version_order)
#  ndx_mhm_provider_id                                      | btree (provider_id)
