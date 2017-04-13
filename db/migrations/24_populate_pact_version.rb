Sequel.migration do
  up do
    run("insert into pact_versions (sha, content, created_at) select sha, content, created_at from pact_version_contents")
  end

  down do
    run("delete from pact_versions")
  end
end
