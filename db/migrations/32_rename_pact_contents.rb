Sequel.migration do
  up do
    rename_table(:pact_contents, :pact_versions)
  end
end
