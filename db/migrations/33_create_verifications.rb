Sequel.migration do
  up do
    create_table(:verifications, charset: 'utf8') do
      primary_key :id
      Integer :number
      Boolean :success, null: false
      String :provider_version, null: false
      String :build_url
      foreign_key :pact_version_content_id, :pact_version_contents, null: false
      index [:pact_version_content_id, :number], unique: true, unique_constraint_name: 'unq_verif_pvc_number'
    end
  end
end
