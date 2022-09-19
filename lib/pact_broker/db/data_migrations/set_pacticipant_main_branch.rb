require "pact_broker/db/data_migrations/helpers"
require "pact_broker/logging"

# Not required now we have the auto_detect_main_branch feature

module PactBroker
  module DB
    module DataMigrations
      class SetPacticipantMainBranch
        include PactBroker::Logging
        extend Helpers

        def self.call(connection, _options = {})
          if required_columns_exist?(connection)
            connection[:pacticipants].select(:id, :name).where(main_branch: nil).each do | pacticipant_row |
              set_main_branch(connection, pacticipant_row)
            end
          end
        end

        def self.set_main_branch(connection, pacticipant_row)
          main_branch_name = calculate_main_branch_name(connection, pacticipant_row)

          if main_branch_name
            connection[:pacticipants].where(id: pacticipant_row[:id], main_branch: nil).update(main_branch: main_branch_name)
            logger.info("Setting main branch for pacticipant", branch: main_branch_name, pacticipant_name: pacticipant_row[:name])
          else
            logger.info("Cannot determine main branch for pacticipant", branch: nil, pacticipant_name: pacticipant_row[:name])
          end
        end

        def self.calculate_main_branch_name(connection, pacticipant_row)
          candidate_main_branch_query = connection[:tags]
            .select(Sequel[:tags][:name])
            .where(Sequel[:tags][:name] => ["main", "master", "develop"])
            .where(Sequel[:tags][:pacticipant_id] => pacticipant_row[:id])

          candidate_main_branch_query
            .from_self
            .select_group(:name)
            .select_append{ count(1).as(count) }
            .order(Sequel.desc(2))
            .limit(1)
            .collect{ |row| row[:name] }
            .first
        end

        def self.required_columns_exist?(connection)
          columns_exist?(connection, :pacticipants, [:name, :id, :main_branch]) &&
            columns_exist?(connection, :tags, [:name, :pacticipant_id])
        end
      end
    end
  end
end
