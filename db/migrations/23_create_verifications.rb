Sequel.migration do
  up do
    create_table(:verifications, charset: 'utf8') do
      primary_key :id
      Integer :number
      Boolean :success, null: false
      String :providerVersion
      String :buildUrl
      foreign_key :pact_id, :pacts, null: false
      index [:pact_id, :number], unique: true
    end
  end

  down do
    drop_table(:verifications)
  end
end