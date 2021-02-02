Sequel.migration do
  change do
    create_table(:environments, charset: 'utf8') do
      primary_key :id
      String :name, nullable: false
      String :label
      String :owners
      DateTime :created_at, nullable: false
      DateTime :updated_at, nullable: false
      index [:name], unique: true, name: "environments_name_index"
    end
  end
end
