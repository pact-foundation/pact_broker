require 'pact_broker/verifications/repository'

# A collection of matrix rows with the same pact publication id
# It's basically a normalised view of a denormalised view :(

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

      def latest_verification
        @latest_verification ||= begin
          verification = matrix_rows.collect do | row|
              row.verification || row.latest_verification_for_consumer_version_tag
            end.compact.sort{ |v1, v2| v1.id <=> v2.id}.last

          if !verification && overall_latest?
            PactBroker::Verifications::Repository.new.find_latest_verification_for(consumer_name, provider_name)
          else
            verification
          end
        end
      end

      def consumer_head_tag_names
        matrix_rows.collect(&:consumer_version_tag_name).compact
      end

      private

      attr_reader :matrix_rows

      def first_row
        @first_row
      end

      def consumer_version_tag_names
        matrix_rows.collect(&:consumer_version_tag_name)
      end
    end
  end
end
