Sequel.migration do
  up do
    rename_table(:pact_contents, :pact_version_contents)
  end
end
