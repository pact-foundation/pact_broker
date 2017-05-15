Sequel.migration do
  up do
    create_table(:config, charset: 'utf8') do
      primary_key :id
      String :name, null: false
      String :type, null: false
      String :value, type: PactBroker::MigrationHelper.large_text_type
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:name], unique: true, unique_constraint_name: 'unq_config_name'
    end
  end
end
