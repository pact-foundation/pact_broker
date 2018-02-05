require 'pact_broker/ui/view_models/matrix_line'

module PactBroker
  module UI
    module ViewDomain
      class MatrixLines < Array

        def initialize rows
          lines = rows.collect do | row |
            PactBroker::UI::ViewDomain::MatrixLine.new(row)
          end
          super(lines.sort)
        end
      end
    end
  end
end
