Sequel.migration do
  up do
    create_table(:verifications, charset: 'utf8') do
      primary_key :id
      Integer :number
      Boolean :success, null: false
      String :provider_version, null: false
      String :build_url
      foreign_key :pact_publication_id, :pact_publications, null: false
      index [:pact_publication_id, :number], unique: true
    end
  end
end
