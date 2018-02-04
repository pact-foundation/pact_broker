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

          # Don't have a URL to view ovewritten pact revisions, so don't show a link for them until we do
          line_group_ids = []
          each do | line |
            line_group_id = [line.consumer_name, line.consumer_version_number, line.provider_name]
            if line_group_ids.include?(line_group_id)
              line.overwritten = true
            else
              line_group_ids << line_group_id
            end
          end
        end
      end
    end
  end
end
