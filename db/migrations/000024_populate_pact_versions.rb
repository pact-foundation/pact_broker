Sequel.migration do
  up do
    run("insert into pact_versions (sha, content, created_at) select sha, content, created_at from pact_version_contents")
    run("update pact_versions set consumer_id = (select consumer_id from all_pacts where pact_version_content_sha = pact_versions.sha limit 1)")
    run("update pact_versions set provider_id = (select provider_id from all_pacts where pact_version_content_sha = pact_versions.sha limit 1)")
    run("delete from pact_versions where consumer_id is null")
  end
end
