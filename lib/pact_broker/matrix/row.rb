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
        [:consumer_name, :consumer_version_order, :pact_revision_number, :provider_name, :provider_version_order, :verification_id].each do | column |
          if send(column) != other.send(column)
            return (send(column) <=> other.send(column)) * -1
          end
        end

        return 0
      end
    end
  end
end
