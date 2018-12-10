require 'pact_broker/matrix/row'
require 'pact_broker/webhooks/webhook'

module PactBroker
  module Matrix
    # A row for each of the overall latest pacts, and a row for each of the latest tagged pacts
    # Rows with a nil consumer_tag_name are the overall latest
    class HeadRow < Row
      set_dataset(:head_matrix)

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

      # When viewing the index, every webhook in the database will match at least one of the rows, so
      # it makes sense to load the entire table and match each webhook to the appropriate row.
      # This will only work when using eager loading. The keys are just blanked out to avoid errors.
      # I don't understand how they work at all.
      # It would be nice to do this declaratively.
      many_to_many :webhooks, :left_key => [], left_primary_key: [], :eager_loader=>(proc do |eo_opts|
        eo_opts[:rows].each do |row|
          row.associations[:webhooks] = []
        end

        PactBroker::Webhooks::Webhook.each do | webhook |
          eo_opts[:rows].each do | row |
            if webhook.is_for?(row)
              row.associations[:webhooks] << webhook
            end
          end
        end
      end)
    end
  end
end

# Table: head_matrix
# Columns:
#  consumer_id               | integer                     |
#  consumer_name             | text                        |
#  consumer_version_id       | integer                     |
#  consumer_version_number   | text                        |
#  consumer_version_order    | integer                     |
#  pact_publication_id       | integer                     |
#  pact_version_id           | integer                     |
#  pact_version_sha          | text                        |
#  pact_revision_number      | integer                     |
#  pact_created_at           | timestamp without time zone |
#  provider_id               | integer                     |
#  provider_name             | text                        |
#  provider_version_id       | integer                     |
#  provider_version_number   | text                        |
#  provider_version_order    | integer                     |
#  verification_id           | integer                     |
#  success                   | boolean                     |
#  verification_number       | integer                     |
#  verification_executed_at  | timestamp without time zone |
#  verification_build_url    | text                        |
#  consumer_version_tag_name | text                        |
