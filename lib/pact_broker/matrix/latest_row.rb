require 'pact_broker/matrix/row'

module PactBroker
  module Matrix
    # Latest pact revision for each consumer version => latest verification
    class LatestRow < Row
      set_dataset(:latest_matrix)

      # For some reason, with MySQL, the success column value
      # comes back as an integer rather than a boolean
      # for the latest_matrix view (but not the matrix view!)
      # Maybe something to do with the union?
      # Haven't investigated as this is an easy enough fix.
      def success
        value = super
        value.nil? ? nil : value == true || value == 1
      end

      def values
        super.merge(success: success)
      end
    end
  end
end
