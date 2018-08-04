Sequel.migration do
  up do
    # consumer_id and provider_id are redundant by avoid making extra joins when creating views
    rows = from(:verifications).select_group(
          Sequel[:verifications][:consumer_id],
          Sequel[:verifications][:pact_version_id],
          Sequel[:verifications][:provider_id],
          Sequel[:verifications][:provider_version_id])
        .select_append{ max(verifications[id]).as(verification_id) }

    # The danger with this migration is that a verification created by an old node will be lost
    from(:latest_verif_id_for_pact_version_and_provider_version).insert(rows)
  end

  down do
    from(:latest_verif_id_for_pact_version_and_provider_version).delete
  end
end
