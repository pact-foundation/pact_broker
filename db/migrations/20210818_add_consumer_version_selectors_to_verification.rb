Sequel.migration do
  change do
    alter_table(:verifications) do
      add_column(:consumer_version_selector_hashes, String)
      add_column(:tag_names, String)
    end
  end
end
