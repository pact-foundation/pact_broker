require 'sequel'

module PactBroker
  module Versions
    class Sequence < Sequel::Model(:version_sequence_number)

      dataset_module do
        # The easiest way to implement a cross database compatible sequence.
        # Sad, I know.
        def next_val
          db.transaction do
            for_update.first
            select_all.update(value: Sequel[:value]+1)
            row = first
            if row
              row.value
            else
              # The first row should have been created in the migration, so this code
              # should only ever be executed in a test context, after we've truncated all the
              # tables after a test.
              # There would be a risk of a race condition creating two rows if this
              # code executed in prod, as I don't think you can lock an empty table
              # to prevent another record being inserted.
              max_version_order = PactBroker::Domain::Version.max(:order)
              value = max_version_order ? max_version_order + 100 : 1
              insert(value: value)
              value
            end
          end
        end
      end
    end
  end
end

# Table: version_sequence_number
# Columns:
#  value | integer | NOT NULL
