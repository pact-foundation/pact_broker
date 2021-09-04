require "pact_broker/db/data_migrations/helpers"

module PactBroker
  module DB
    module DataMigrations
      class CreateBranches
        extend Helpers

        def self.call connection
          if required_columns_exist?(connection)
            branch_ids = create_branch_versions(connection)
            upsert_branch_heads(connection, branch_ids)
          end
        end

        def self.required_columns_exist?(connection)
          column_exists?(connection, :versions, :branch) &&
            connection.table_exists?(:branches) &&
            connection.table_exists?(:branch_versions) &&
            connection.table_exists?(:branch_heads)
        end

        def self.create_branch_versions(connection)
          versions_without_a_branch_version(connection).collect do | version |
            create_branch_version(connection, version)
          end.uniq
        end

        def self.upsert_branch_heads(connection, branch_ids)
          branch_ids.each do | branch_id |
            upsert_branch_head(connection, branch_id)
          end
        end

        def self.versions_without_a_branch_version(connection)
          branch_versions_join = {
            Sequel[:versions][:id] => Sequel[:branch_versions][:version_id],
            Sequel[:branch_versions][:branch_name] => Sequel[:versions][:branch]
          }

          connection[:versions]
            .select(Sequel[:versions].*)
            .exclude(branch: nil)
            .left_outer_join(:branch_versions, branch_versions_join)
            .where(Sequel[:branch_versions][:branch_name] => nil)
            .order(:pacticipant_id, :order)
        end

        def self.create_branch_version(connection, version)
          branch_values = {
            name: version[:branch],
            pacticipant_id: version[:pacticipant_id],
            created_at: version[:created_at],
            updated_at: version[:created_at]
          }
          connection[:branches].insert_ignore.insert(branch_values)
          branch_id = connection[:branches].select(:id).where(pacticipant_id: version[:pacticipant_id], name: version[:branch]).single_record[:id]

          branch_version_values = {
            pacticipant_id: version[:pacticipant_id],
            version_id: version[:id],
            version_order: version[:order],
            branch_id: branch_id,
            branch_name: version[:branch],
            created_at: version[:created_at],
            updated_at: version[:created_at]
          }

          connection[:branch_versions].insert_ignore.insert(branch_version_values)
          branch_id
        end

        def self.upsert_branch_head(connection, branch_id)
          latest_branch_version = connection[:branch_versions].where(branch_id: branch_id).order(:version_order).last

          if connection[:branch_heads].where(branch_id: branch_id).empty?
            branch_head_values = {
              pacticipant_id: latest_branch_version[:pacticipant_id],
              branch_id: branch_id,
              branch_version_id: latest_branch_version[:id],
              version_id: latest_branch_version[:version_id],
              branch_name: latest_branch_version[:branch_name]
            }
            connection[:branch_heads].insert(branch_head_values)
          else
            connection[:branch_heads]
              .where(branch_id: branch_id)
              .update(
                branch_version_id: latest_branch_version[:id],
                version_id: latest_branch_version[:version_id]
              )
          end
        end
      end
    end
  end
end
