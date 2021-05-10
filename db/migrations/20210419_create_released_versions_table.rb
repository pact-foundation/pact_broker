Sequel.migration do
  change do
    create_table(:released_versions, charset: 'utf8') do
      primary_key :id
      String :uuid, null: false
      foreign_key :version_id, :versions, null: false
      Integer :pacticipant_id, null: false
      foreign_key :environment_id, :environments, null: false
      DateTime :created_at
      DateTime :updated_at
      DateTime :support_ended_at
      index [:uuid], unique: true, name: "released_versions_uuid_index"
      index [:version_id, :environment_id], unique: true, name: "released_versions_version_id_environment_id_index"
      index [:support_ended_at], name: "released_version_support_ended_at_index"
    end
  end
end
