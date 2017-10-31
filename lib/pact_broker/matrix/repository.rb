require 'pact_broker/repositories/helpers'

module PactBroker
  module Matrix
    class Repository
      include PactBroker::Repositories::Helpers
      include PactBroker::Repositories

      # Return the latest matrix row (pact/verification) for each consumer_version_number/provider_version_number
      def find selectors, options = {}
        # The group with the nil provider_version_numbers will be the results of the left outer join
        # that don't have verifications, so we need to include them all.
        lines = find_all(selectors)
          .group_by{|line| [line[:consumer_name], line[:consumer_version_number], line[:provider_name], line[:provider_version_number]]}
          .values
          .collect{ | lines | lines.first[:provider_version_number].nil? ? lines : lines.last }
          .flatten

        if options.key?(:success)
          lines = lines.select{ |l| options[:success].include?(l[:success]) }
        end

        lines
      end

      def find_for_consumer_and_provider pacticipant_1_name, pacticipant_2_name
        selectors = [{ pacticipant_name: pacticipant_1_name }, { pacticipant_name: pacticipant_2_name }]
        find_all(selectors)
          .sort{|l1, l2| l2[:consumer_version_order] <=> l1[:consumer_version_order]}
      end

      def find_compatible_pacticipant_versions selectors
        find(selectors).select{ |line | line[:success] }
      end

      ##
      # If the version is nil, it means all versions for that pacticipant are to be included
      #
      def find_all selectors
        selectors = look_up_versions_for_tags(selectors)

        query = PactBroker::Pacts::LatestPactPublicationsByConsumerVersion
          .select_append(:consumer_version_number, :provider_name, :consumer_name, :provider_version_id, :provider_version_number, :success)
          .select_append(Sequel[:latest_pact_publications_by_consumer_versions][:created_at].as(:pact_created_at))
          .select_append(Sequel[:all_verifications][:number])
          .select_append(Sequel[:all_verifications][:id].as(:verification_id))
          .select_append(Sequel[:execution_date].as(:verification_executed_at))
          .left_outer_join(:all_verifications, pact_version_id: :pact_version_id)

        if selectors.size == 1
          query = where_consumer_or_provider_is(selectors.first, query)
        else
          query = where_consumer_and_provider_within(selectors, query)
        end

        query.order(:execution_date, :verification_id)
          .collect(&:values)
      end

      def look_up_versions_for_tags(selectors)
        selectors.collect do | selector |
          if selector[:latest_tag]
            version = version_repository.find_by_latest_tag(selector[:pacticipant_name], selector[:latest_tag])
            # validation in resource should ensure we always have a version
            {
              pacticipant_name: selector[:pacticipant_name],
              pacticipant_version_number: version.number
            }
          else
            selector
          end
        end
      end

      def where_consumer_and_provider_within selectors, query
          query.where{
            Sequel.&(
              Sequel.|(
                *selectors.collect{ |s| s[:pacticipant_version_number] ? Sequel.&(consumer_name: s[:pacticipant_name], consumer_version_number: s[:pacticipant_version_number]) :  Sequel.&(consumer_name: s[:pacticipant_name]) }
              ),
              Sequel.|(
                *(selectors.collect{ |s| s[:pacticipant_version_number] ? Sequel.&(provider_name: s[:pacticipant_name], provider_version_number: s[:pacticipant_version_number]) :  Sequel.&(provider_name: s[:pacticipant_name]) } +
                  selectors.collect{ |s| Sequel.&(provider_name: s[:pacticipant_name], provider_version_number: nil) })
              )
            )
          }
      end

      def where_consumer_or_provider_is s, query
        query.where{
          Sequel.|(
            s[:pacticipant_version_number] ? Sequel.&(consumer_name: s[:pacticipant_name], consumer_version_number: s[:pacticipant_version_number]) :  Sequel.&(consumer_name: s[:pacticipant_name]),
            s[:pacticipant_version_number] ? Sequel.&(provider_name: s[:pacticipant_name], provider_version_number: s[:pacticipant_version_number]) :  Sequel.&(provider_name: s[:pacticipant_name])
          )
        }
      end
    end
  end
end
