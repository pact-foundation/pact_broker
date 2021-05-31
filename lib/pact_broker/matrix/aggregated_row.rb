require 'forwardable'
require 'pact_broker/verifications/repository'

# A collection of matrix rows with the same pact publication id
# It's basically a normalised view of a denormalised view :(
# A pact publication may be the overall latest, and/or the latest for a tag
module PactBroker
  module Matrix
    class AggregatedRow
      extend Forwardable

      delegate [:consumer, :consumer_name, :consumer_version, :consumer_version_number, :consumer_version_order, :consumer_version_tags] => :first_row
      delegate [:provider, :provider_name, :provider_version, :provider_version_number, :provider_version_order, :provider_version_tags] => :first_row
      delegate [:pact, :pact_version, :pact_revision_number, :webhooks, :latest_triggered_webhooks, :'<=>'] => :first_row
      delegate [:verification_id, :verification] => :first_row

      def initialize matrix_rows
        @matrix_rows = matrix_rows
        @first_row = matrix_rows.first
      end

      def overall_latest?
        !!matrix_rows.find{ | row| row.consumer_version_tag_name.nil? }
      end

      # If this comes back nil, it won't be "cached", but it's a reasonably
      # quick query, so it's probably ok.
      # The collection of pacts that belong to the same tag can be considered
      # a pseudo branch. Find the latest verification for each pseudo branch
      # and return the most recent. If this pact is the most recent overall,
      # and there were no verifications found for any of the tags, then
      # return the most recent verification
      def latest_verification_for_pseudo_branch
        @latest_verification ||= begin
          verification = matrix_rows.collect do | row|
              row.verification || latest_verification_for_consumer_version_tag(row)
          end.compact.sort_by(&:id).last

          if !verification && overall_latest?
            overall_latest_verification
          else
            verification
          end
        end
      end

      def latest_verification_for_pact_version
        @latest_verificaton_for_pact_version ||= begin
          matrix_rows.collect(&:verification).compact.sort_by(&:id).last
        end
      end

      # The list of tag names for which this pact publication is the most recent with that tag
      # There could, however, be a later consumer version that does't have a pact (perhaps because it was deleted)
      # that has the same tag.
      # TODO show a warning when the data is "corrupted" as above.
      def consumer_head_tag_names
        matrix_rows.collect(&:consumer_version_tag_name).compact
      end

      private

      attr_reader :matrix_rows, :first_row

      def latest_verification_for_consumer_version_tag row
        row.latest_verification_for_consumer_version_tag if row.consumer_version_tag_name
      end

      def overall_latest_verification
        # not eager loaded because it shouldn't be called that often
        first_row.latest_verification_for_consumer_and_provider
      end

      def consumer_version_tag_names
        matrix_rows.collect(&:consumer_version_tag_name)
      end
    end
  end
end
