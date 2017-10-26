require 'pact_broker/repositories/helpers'

module PactBroker
  module Matrix
    class Repository
      include PactBroker::Repositories::Helpers
      include PactBroker::Repositories

      def find criteria
        find_all(criteria)
          .group_by{|line| [line[:consumer_version_number], line[:provider_version_number]]}
          .values
          .collect{ | lines | lines.first[:provider_version_number].nil? ? lines : lines.last }
          .flatten
      end

      def find_for_consumer_and_provider pacticipant_1_name, pacticipant_2_name
        find_all({pacticipant_1_name => nil, pacticipant_2_name => nil})
          .sort{|l1, l2| l2[:consumer_version_order] <=> l1[:consumer_version_order]}
      end

      ##
      # criteria Hash of pacticipant_name => version
      # Ihe value is nil, it means all versions for that pacticipant are to be included
      # Returns a list of matrix lines indicating the compatible versions
      #
      def find_compatible_pacticipant_versions criteria
        find(criteria).select{ |line | line[:success] }
      end

      def find_all criteria
        PactBroker::Pacts::LatestPactPublicationsByConsumerVersion
          .select_append(:consumer_version_number, :provider_name, :consumer_name, :provider_version_id, :provider_version_number, :success)
          .select_append(Sequel[:latest_pact_publications_by_consumer_versions][:created_at].as(:pact_created_at))
          .select_append(Sequel[:all_verifications][:number])
          .select_append(Sequel[:all_verifications][:id].as(:verification_id))
          .select_append(Sequel[:execution_date].as(:verification_executed_at))
          .left_outer_join(:all_verifications, pact_version_id: :pact_version_id)
          .where{
            Sequel.&(
              Sequel.|(
                *criteria.collect{|key, value| value ? Sequel.&(consumer_name: key, consumer_version_number: value) :  Sequel.&(consumer_name: key) }
              ),
              Sequel.|(
                *(criteria.collect{|key, value| value ? Sequel.&(provider_name: key, provider_version_number: value) :  Sequel.&(provider_name: key) } +
                  criteria.collect{|key, value| Sequel.&(provider_name: key, provider_version_number: nil) })
              )
            )
          }
          .order(:execution_date, :verification_id)
          .collect(&:values)
      end
    end
  end
end
