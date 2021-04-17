Sequel.migration do
  change do
    create_table(:version_in_environments, charset: 'utf8') do
      primary_key :id
      String :uuid, null: false
      foreign_key :version_id, :versions, null: false
      Integer :pacticipant_id, null: false
      foreign_key :environment_id, :environments, null: false
      String :target
      DateTime :created_at
      DateTime :updated_at
      DateTime :ended_at
      index [:uuid], unique: true, name: "version_in_environments_uuid_index"
      index [:pacticipant_id, :currently_deployed], name: "deployed_versions_pacticipant_id_currently_deployed_index"
    end
  end
end
