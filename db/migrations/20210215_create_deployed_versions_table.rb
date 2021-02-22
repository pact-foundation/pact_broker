Sequel.migration do
  change do
    create_table(:deployed_versions, charset: 'utf8') do
      primary_key :id
      String :uuid, null: false
      foreign_key :version_id, :versions, null: false
      Integer :pacticipant_id, null: false
      foreign_key :environment_id, :environments, null: false
      Boolean :replaced_previous_deployed_version
      Boolean :currently_deployed, null: false
      DateTime :created_at, nullable: false
      DateTime :updated_at, nullable: false
      DateTime :undeployed_at
      index [:uuid], unique: true, name: "deployed_versions_uuid_index"
      index [:pacticipant_id, :currently_deployed], name: "deployed_versions_pacticipant_id_currently_deployed_index"
    end
  end
end
