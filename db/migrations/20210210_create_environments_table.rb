Sequel.migration do
  change do
    create_table(:environments, charset: 'utf8') do
      primary_key :id
      String :uuid, null: false
      String :name, null: false
      String :display_name
      Boolean :production, null: false
      String :contacts
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:uuid], unique: true, name: "environments_uuid_index"
      index [:name], unique: true, name: "environments_name_index"
    end
  end
end
