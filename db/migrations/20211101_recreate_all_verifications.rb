Sequel.migration do
  up do
    # need to fully qualify build_url because versions now has a build_url too.
    # We don't use this view any more but we get an error when dropping the integrations
    # view if we don't update this, so it must force some re-calculation to be done.
    create_or_replace_view(:all_verifications,
      from(:verifications).select(
        Sequel[:verifications][:id],
        Sequel[:verifications][:number],
        :success,
        :provider_version_id,
        Sequel[:v][:number].as(:provider_version_number),
        Sequel[:v][:order].as(:provider_version_order),
        Sequel[:v][:build_url],
        :pact_version_id,
        :execution_date,
        Sequel[:verifications][:created_at]
        ).join(:versions, {id: :provider_version_id}, {:table_alias => :v})
    )
  end

  down do
  end
end
