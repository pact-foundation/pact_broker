require_relative 'migration_helper'

Sequel.migration do
  change do
    create_table(:webhook_events, charset: 'utf8') do
      primary_key :id
      foreign_key :webhook_id, :webhooks, on_delete: :cascade
      String :name
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:id, :name], unique: true, name: 'uq_webhook_id_name'
    end
  end
end
