Sequel.migration do
  change do
    create_table(:triggered_webhooks, charset: "utf8") do
      primary_key :id
      String :trigger_uuid, null: false
      String :trigger_type, null: false # publication or manual
      foreign_key :pact_publication_id, :pact_publications, null: false
      foreign_key :webhook_id, :webhooks
      String :webhook_uuid, null: false # keep so we can group executions even when webhook is deleted
      foreign_key :consumer_id, :pacticipants, null: false
      foreign_key :provider_id, :pacticipants, null: false
      String :status, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:webhook_id, :trigger_uuid], unique: true, name: "uq_triggered_webhook_wi"
      index [:pact_publication_id, :webhook_id, :trigger_uuid], unique: true, name: "uq_triggered_webhook_ppi_wi"
    end
  end
end
