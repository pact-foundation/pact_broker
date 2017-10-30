Sequel.migration do
  up do
    drop_view(:latest_tagged_pacts)
    drop_view(:latest_pacts)
    drop_view(:all_pacts)
    drop_table(:pacts)
    drop_table(:pact_version_contents)
  end
end
