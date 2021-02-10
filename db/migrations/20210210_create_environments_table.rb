Sequel.migration do
  change do
    create_table(:environments, charset: 'utf8') do
      primary_key :id
      String :uuid, nullable: false
      String :name, nullable: false
      String :label
      String :owners
      DateTime :created_at, nullable: false
      DateTime :updated_at, nullable: false
      index [:uuid], unique: true, name: "environments_uuid_index"
      index [:name], unique: true, name: "environments_name_index"
    end
  end
end
