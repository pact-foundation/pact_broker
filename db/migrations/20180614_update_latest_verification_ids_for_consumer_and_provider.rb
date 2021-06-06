require_relative "../ddl_statements/latest_verification_ids_for_consumer_and_provider"

Sequel.migration do
  up do
    # The latest verification id for each consumer/provider
    create_or_replace_view(:latest_verification_ids_for_consumer_and_provider,
          LATEST_VERIFICATION_IDS_FOR_CONSUMER_AND_PROVIDER_V2)
  end

  down do
    # The latest verification id for each consumer/provider
    create_or_replace_view(:latest_verification_ids_for_consumer_and_provider,
      LATEST_VERIFICATION_IDS_FOR_CONSUMER_AND_PROVIDER_V1)
  end
end
