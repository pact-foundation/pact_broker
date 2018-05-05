Sequel.migration do
  up do
    from(:pact_versions).update(:verifiable_content_sha => :sha)
  end

  down do

  end
end
