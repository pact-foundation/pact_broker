require 'pact_broker/repositories/helpers'

module PactBroker
  module Matrix
    class Row < Sequel::Model
      set_dataset(:matrix)

      dataset_module do
        include PactBroker::Repositories::Helpers
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
