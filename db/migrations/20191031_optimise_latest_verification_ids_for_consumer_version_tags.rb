require_relative "../ddl_statements"

Sequel.migration do
  up do
    create_or_replace_view(:latest_verification_ids_for_consumer_version_tags,
      LATEST_VERIFICATION_IDS_FOR_CONSUMER_VERSION_TAGS_V3)
  end

  down do
    create_or_replace_view(:latest_verification_ids_for_consumer_version_tags,
      LATEST_VERIFICATION_IDS_FOR_CONSUMER_VERSION_TAGS_V2)
  end
end
