require "sequel"
require "pact_broker/repositories/helpers"

module PactBroker
  module Verifications
    class Sequence < Sequel::Model(:verification_sequence_number)
      dataset_module do
        # The easiest way to implement a cross database compatible sequence.
        # Sad, I know.
        def next_val
          if PactBroker::Repositories::Helpers.postgres?
            db.execute("SELECT nextval('verification_number_sequence') as val") { |v| v.first["val"].to_i }
          else
            db.transaction do
              for_update.first
              select_all.update(value: Sequel[:value]+1)
              row = first
              if row
                row.value
              else
                # The first row should have been created in the migration, so this code
                # should only ever be executed in a test context.
                # There would be a risk of a race condition creating two rows if this
                # code executed in prod, as I don't think you can lock an empty table
                # to prevent another record being inserted.
                max_verification_number = PactBroker::Domain::Verification.max(:number)
                value = max_verification_number ? max_verification_number + 100 : 1
                insert(value: value)
                value
              end
            end
          end
        end
      end
    end
  end
end

# Table: verification_sequence_number
# Columns:
#  value | integer | NOT NULL
