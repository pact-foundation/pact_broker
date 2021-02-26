Sequel.migration do
  change do
    create_table(:environments, charset: 'utf8') do
      primary_key :id
      String :uuid
      String :name
      String :display_name
      Boolean :production
      String :contacts
      DateTime :created_at
      DateTime :updated_at
      index [:uuid], unique: true, name: "environments_uuid_index"
      index [:name], unique: true, name: "environments_name_index"
    end
  end
end
