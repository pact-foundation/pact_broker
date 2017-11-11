require 'pact_broker/repositories/helpers'

module PactBroker
  module Matrix
    class Row < Sequel::Model(:matrix)

      dataset_module do
        include PactBroker::Repositories::Helpers

        def matching_selectors selectors
          if selectors.size == 1
            where_consumer_or_provider_is(selectors.first)
          else
            where_consumer_and_provider_in(selectors)
          end
        end

        def where_consumer_and_provider_in selectors
          where{
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

        def where_consumer_or_provider_is s
          where{
            Sequel.|(
              s[:pacticipant_version_number] ? Sequel.&(consumer_name: s[:pacticipant_name], consumer_version_number: s[:pacticipant_version_number]) :  Sequel.&(consumer_name: s[:pacticipant_name]),
              s[:pacticipant_version_number] ? Sequel.&(provider_name: s[:pacticipant_name], provider_version_number: s[:pacticipant_version_number]) :  Sequel.&(provider_name: s[:pacticipant_name])
            )
          }
        end

        def order_by_names_ascending_most_recent_first
          order(
            Sequel.asc(:consumer_name),
            Sequel.desc(:consumer_version_order),
            Sequel.desc(:pact_revision_number),
            Sequel.asc(:provider_name),
            Sequel.desc(:provider_version_order),
            Sequel.desc(:verification_id))
        end
      end

      def summary
        "#{consumer_name}#{consumer_version_number} #{provider_name}#{provider_version_number || '?'} (r#{pact_revision_number}n#{verification_number || '?'})"
      end

      # Add logic for ignoring case
      def <=> other
        comparisons = [
          compare_name_asc(consumer_name, other.consumer_name),
          compare_number_desc(consumer_version_order, other.consumer_version_order),
          compare_number_desc(pact_revision_number, other.pact_revision_number),
          compare_name_asc(provider_name, other.provider_name),
          compare_number_desc(provider_version_order, other.provider_version_order),
          compare_number_desc(verification_id, other.verification_id)
        ]

        comparisons.find{|c| c != 0 } || 0

      end

      def compare_name_asc name1, name2
        name1 <=> name2
      end

      def compare_number_desc number1, number2
        if number1 && number2
          number2 <=> number1
        elsif number1
          1
        else
          -1
        end
      end
    end
  end
end
