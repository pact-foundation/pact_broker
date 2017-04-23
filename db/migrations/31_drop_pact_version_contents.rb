Sequel.migration do
  up do
    drop_table(:pact_version_contents)
  end
end
