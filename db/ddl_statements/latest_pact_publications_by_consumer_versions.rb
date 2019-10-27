def latest_pact_publications_by_consumer_versions_v2(connection = nil)
  "select app.*
  from latest_pact_publication_ids_for_consumer_versions lpp
  inner join all_pact_publications app
  on lpp.consumer_version_id = app.consumer_version_id
  and lpp.pact_publication_id = app.id
  and lpp.provider_id = app.provider_id"
end

# Don't need all the join keys, just pact_publication_id
def latest_pact_publications_by_consumer_versions_v3(connection)
  "select app.*
  from latest_pact_publication_ids_for_consumer_versions lpp
  inner join all_pact_publications app
  on lpp.pact_publication_id = app.id"
end
