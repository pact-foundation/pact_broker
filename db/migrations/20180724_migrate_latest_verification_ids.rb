Sequel.migration do
  up do
    # Not sure if we need the provider_id, but it might come in handy
    rows = from(:verifications).select_group(
          Sequel[:verifications][:pact_version_id],
          Sequel[:verifications][:provider_version_id],
          Sequel[:versions][:pacticipant_id].as(:provider_id))
        .select_append{ max(verifications[id]).as(verification_id) }
        .join(:versions, { Sequel[:verifications][:provider_version_id] => Sequel[:versions][:id] })

    # The danger with this migration is that a verification created by an old node will be lost
    from(:latest_verification_id_for_pact_version_and_provider_version).insert(rows)
  end

  down do

  end
end
