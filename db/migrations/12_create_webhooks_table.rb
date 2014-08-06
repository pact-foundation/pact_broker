Sequel.migration do
  change do
    create_table(:webhooks) do
      primary_key :id
      String :uuid, null: false
      String :method, null: false
      String :url, null: false
      String :body
      foreign_key :consumer_id, :pacticipants, null: false
      foreign_key :provider_id, :pacticipants, null: false
    end

    create_table(:webhook_headers) do
      String :name, null: false
      String :value
      foreign_key :webhook_id, :webhooks, null: false
      primary_key [:webhook_id, :name], :name=>:webhooks_headers_pk
    end
  end
end
