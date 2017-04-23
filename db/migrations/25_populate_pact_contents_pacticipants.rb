Sequel.migration do
  up do
    run("update pact_contents set consumer_id = (select consumer_id from all_pacts where pact_version_content_sha = pact_contents.sha limit 1)")
    run("update pact_contents set provider_id = (select provider_id from all_pacts where pact_version_content_sha = pact_contents.sha limit 1)")
    run("delete from pact_contents where consumer_id is null")
  end
end
