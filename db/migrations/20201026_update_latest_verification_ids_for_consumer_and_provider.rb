require_relative 'migration_helper'
require_relative '../ddl_statements/latest_verification_ids_for_consumer_and_provider'

Sequel.migration do
  up do
    create_or_replace_view(:latest_verification_ids_for_consumer_and_provider,
      LATEST_VERIFICATION_IDS_FOR_CONSUMER_AND_PROVIDER_V3)
  end

  down do
    create_or_replace_view(:latest_verification_ids_for_consumer_and_provider,
      LATEST_VERIFICATION_IDS_FOR_CONSUMER_AND_PROVIDER_V2)
  end
end
