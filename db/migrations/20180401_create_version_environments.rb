Sequel.migration do
  change do
    create_table(:version_environments, charset: 'utf8') do
      String :name, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      foreign_key :version_id, :versions, null: false, on_delete: :cascade, foreign_key_constraint_name: "fk_verenv_versions"
      primary_key [:version_id, :name], name: :environments_pk
    end
  end
end
