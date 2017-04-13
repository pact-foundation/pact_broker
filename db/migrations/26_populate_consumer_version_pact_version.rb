Sequel.migration do
  up do
    run("insert into consumer_versions_pact_versions
        (id, consumer_version_id, provider_id, revision_number, pact_version_id, created_at)
      select ap.id, ap.consumer_version_id, ap.provider_id, 1, pv.id, ap.updated_at
      from all_pacts ap inner join pact_versions pv
      on pv.sha = ap.pact_version_content_sha")
  end

  down do
    run("delete from consumer_versions_pact_versions")
  end
end
