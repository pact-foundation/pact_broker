Sequel.migration do
  change do
    create_table(:webhooks) do
      primary_key :id
      String :uuid, null: false, unique: true, unique_constraint_name: 'uq_webhook_uuid'
      String :method, null: false
      String :url, null: false
      String :body
      Boolean :is_json_request_body
      foreign_key :consumer_id, :pacticipants, null: false, foreign_key_constraint_name: 'fk_webhooks_consumer'
      foreign_key :provider_id, :pacticipants, null: false, foreign_key_constraint_name: 'fk_webhooks_provider'
    end

    create_table(:webhook_headers) do
      String :name, null: false
      String :value
      foreign_key :webhook_id, :webhooks, null: false, foreign_key_constraint_name: 'fk_webhookheaders_webhooks'
      primary_key [:webhook_id, :name], :name=>:webhooks_headers_pk
    end
  end
end
