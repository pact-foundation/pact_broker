require_relative "migration_helper"

Sequel.migration do
  up do
    from(:webhooks).each do | webhook |
      from(:webhook_events).insert(
        webhook_id: webhook[:id],
        name: "contract_content_changed",
        created_at: DateTime.now,
        updated_at: DateTime.now
      )
    end
  end

  down do

  end
end
