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
    end
  end
end
