Sequel.migration do
  change do
    create_table(:currently_deployed_version_ids, charset: 'utf8') do
      primary_key :id
      String :target
      Boolean :deployment_complete
      foreign_key :pacticipant_id, :pacticipants, null: false, on_delete: :cascade
      foreign_key :environment_id, :environments, null: false, on_delete: :cascade
      foreign_key :version_id, :versions, null: false, on_delete: :cascade
      foreign_key :deployed_version_id, null: false, on_delete: :cascade
      index [:pacticipant_id, :environment_id, :target, :deployment_complete], unique: true, name: "currently_deployed_version_pacticipant_environment_target_deployment_complete_index"
    end
  end
end
