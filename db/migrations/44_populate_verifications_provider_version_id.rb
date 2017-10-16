Sequel.migration do
  up do
    from(:verifications)
      .select(Sequel[:verifications][:id], :provider_version, :provider_id, Sequel[:verifications][:created_at])
      .join(:pact_versions, {id: :pact_version_id})
      .each do | line |
        version = from(:versions)
          .where(number: line[:provider_version], pacticipant_id: line[:provider_id]).single_record
        version_id = if version
          version[:id]
        else
          from(:versions).insert(
              number: line[:provider_version],
              pacticipant_id: line[:provider_id],
              created_at: line[:created_at],
              updated_at: line[:created_at]
          )
        end
        from(:verifications).where(id: line[:id]).update(provider_version_id: version_id)
      end
  end

  down do
  end
end
