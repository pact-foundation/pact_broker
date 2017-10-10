require 'pact_broker/repositories/helpers'

module PactBroker
  module Matrix
    class Repository
      include PactBroker::Repositories::Helpers
      include PactBroker::Repositories

      def find pacticipant_1_name, pacticipant_2_name
        version_ids = PactBroker::Domain::Version.select(Sequel[:versions][:id])
          .join(:pacticipants, id: :pacticipant_id)
          .where(Sequel[:pacticipants][:name] => [pacticipant_1_name, pacticipant_2_name])
        find_for_version_ids(version_ids)
          .sort{|l1, l2| l2[:consumer_version_order] <=> l1[:consumer_version_order]}
      end

      ##
      # candidate_versions Hash of candidate name to version
      # Returns a list of matrix lines indicating the compatible versions
      def find_compatible_pacticipant_versions criteria
        version_ids = criteria.collect do | key, value |
          if value
            version_repository.find_by_pacticipant_name_and_number(key, value).id
          else
            pacticipant_repository.find_by_name(key).versions.collect(&:id)
          end
        end.flatten

        find_for_version_ids(version_ids)
          .group_by{|line| [line[:consumer_version_number], line[:provider_version_number]]}
          .values
          .collect(&:last)
          .select{ |line | line[:success] }
      end

      def find_for_version_ids version_ids
        PactBroker::Pacts::LatestPactPublicationsByConsumerVersion
          .select_append(:consumer_version_number, :provider_name, :consumer_name, :provider_version_id, :provider_version_number, :success)
          .select_append(Sequel[:latest_pact_publications_by_consumer_versions][:created_at].as(:pact_created_at))
          .select_append(Sequel[:all_verifications][:number])
          .select_append(Sequel[:all_verifications][:id].as(:verification_id))
          .select_append(Sequel[:all_verifications][:execution_date].as(:verification_executed_at))
          .left_outer_join(:all_verifications, pact_version_id: :pact_version_id)
          .where(provider_version_id: version_ids).or(provider_version_id: nil)
          .where(consumer_version_id: version_ids)
          .order(:execution_date, :verification_id)
          .collect(&:values)
      end
    end
  end
end
