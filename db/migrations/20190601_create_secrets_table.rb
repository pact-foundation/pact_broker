Sequel.migration do
  change do
    create_table(:secrets, charset: 'utf8') do
      primary_key :id
      String :uuid, null: false, unique: true, unique_constraint_name: 'uq_secrets_uuid'
      String :name, null: false, unique: true, unique_constraint_name: 'uq_secrets_name'
      String :encrypted_value, null: false
      String :encrypted_value_iv, null: false, unique: true, unique_constraint_name: 'uq_secrets_value_iv'
      String :key_id
      String :algorithm, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
