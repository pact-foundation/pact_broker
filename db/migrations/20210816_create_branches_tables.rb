Sequel.migration do
  change do
    create_table(:branches, charset: "utf8") do
      primary_key :id
      String :name
      foreign_key :pacticipant_id, :pacticipants, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:name, :pacticipant_id], unique: true, name: :branches_name_pacticipant_id_index
    end

    create_table(:branch_versions, charset: "utf8") do
      primary_key :id
      foreign_key :branch_id, :branches, null: false, foreign_key_constraint_name: :branch_versions_branches_fk
      String :branch_name, null: false # duplicate
      foreign_key :version_id, :versions, null: false, foreign_key_constraint_name: :branch_versions_versions_fk
      Integer :version_order, null: false
      Integer :pacticipant_id, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:branch_id, :version_id], unique: true, name: :branch_versions_branch_id_version_id_index
      index [:pacticipant_id, :branch_id, :version_order], name: :branch_versions_pacticipant_id_branch_id_version_order_index
    end
  end
end
