Sequel.migration do
  up do
    create_or_replace_view(:latest_verification_numbers,
      "SELECT pact_version_id, MAX(number) latest_number
          FROM verifications
          GROUP BY pact_version_id")

    # The most recent verification for each pact version
    # provider_version is DEPRECATED, use provider_version_number
    create_or_replace_view(:latest_verifications,
      "SELECT v.id, v.number, v.success, s.number as provider_version, v.build_url, v.pact_version_id, v.execution_date, v.created_at, v.provider_version_id, s.number as provider_version_number
        FROM verifications v
        INNER JOIN latest_verification_numbers lv
          ON v.pact_version_id = lv.pact_version_id
          AND v.number = lv.latest_number
        INNER JOIN versions s on v.provider_version_id = s.id"
    )
  end
end
