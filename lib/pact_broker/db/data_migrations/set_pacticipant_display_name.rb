
module PactBroker
  module Db
    module DataMigrations
      class SetPacticipantDisplayName
        extend Helpers
        extend PactBroker::Pacticipants::GenerateDisplayName

        def self.call(connection)
          if columns_exist?(connection, :pacticipants, [:name, :display_name])
            connection[:pacticipants].where(display_name: nil).each do | row |
              connection[:pacticipants]
                .where(id: row[:id])
                .update(display_name: generate_display_name(row[:name]))
            end
          end
        end
      end
    end
  end
end
