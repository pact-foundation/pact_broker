Sequel.migration do
  up do
    create_table(:verifications, charset: "utf8") do
      primary_key :id
      Integer :number
      Boolean :success, null: false
      String :provider_version, null: false
      String :build_url
      foreign_key :pact_version_id, :pact_versions, null: false
      DateTime :execution_date, null: false
      DateTime :created_at, null: false
      index [:pact_version_id, :number], unique: true
    end
  end
end
