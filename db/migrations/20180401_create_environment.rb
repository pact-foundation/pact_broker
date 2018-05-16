Sequel.migration do
  change do
    create_table(:version_environments, charset: 'utf8') do
      String :name, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      foreign_key :version_id, :versions, null: false
      primary_key [:version_id, :name], name: :environments_pk
    end
  end
end
