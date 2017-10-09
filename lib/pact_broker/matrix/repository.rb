require 'pact_broker/repositories/helpers'

module PactBroker
  module Matrix
    class Repository
      include PactBroker::Repositories::Helpers
      include PactBroker::Repositories

      def find pacticipant_1_name, pacticipant_2_name
        PactBroker::Pacts::LatestPactPublicationsByConsumerVersion
          .left_outer_join(:latest_verifications, pact_version_id: :pact_version_id)
          .pacticipants(pacticipant_1_name, pacticipant_2_name)
          .reverse(:consumer_version_order)
          .all
          .collect(&:values)
      end

      ##
      # candidate_versions Hash of candidate name to version
      # Returns a list of matrix lines indicating the compatible versions
      def find_compatible_pacticipant_versions criteria
        version_ids = criteria.collect do | key, value |
          version_repository.find_by_pacticipant_name_and_number(key, value).id
        end

        query = PactBroker::Pacts::LatestPactPublicationsByConsumerVersion
          .select_append(:consumer_version_number, :provider_name, :consumer_name, :provider_version_id, :provider_version_number, :success, :execution_date)
          .select_append(Sequel[:all_verifications][:number])
          .select_append(Sequel[:all_verifications][:id].as(:verification_id))
          .left_outer_join(:all_verifications, pact_version_id: :pact_version_id)
          .where(provider_version_id: version_ids)
          .where(consumer_version_id: version_ids)
          .order(:execution_date, :verification_id)
          .collect(&:values)
          .group_by{|line| [line[:consumer_version_number], line[:provider_version_number]]}
          .values
          .collect(&:last)
          .select{ |line | line[:success] }
      end
    end
  end
end
