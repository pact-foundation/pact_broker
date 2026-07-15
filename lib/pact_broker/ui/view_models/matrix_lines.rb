
module PactBroker
  module Ui
    module ViewModels
      class MatrixLines < Array

        def initialize rows, options = {}
          lines = rows.collect do | row |
            PactBroker::Ui::ViewModels::MatrixLine.new(row, options)
          end
          super(lines.sort)
        end
      end
    end
  end
end
