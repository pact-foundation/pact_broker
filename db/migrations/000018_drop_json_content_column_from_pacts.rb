require 'digest/sha1'
require_relative 'migration_helper'

Sequel.migration do
  change do
    drop_view(:latest_pacts)
    drop_view(:latest_pact_consumer_version_orders)
    drop_view(:all_pacts)

    alter_table(:pacts) do
      drop_column(:json_content)
    end
  end
end
