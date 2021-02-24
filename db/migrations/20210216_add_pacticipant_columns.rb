Sequel.migration do
  change do
    alter_table(:pacticipants) do
      add_column(:display_name, String)
      add_column(:repository_name, String)
      add_column(:repository_organization, String)
      add_column(:main_development_branches, String)
    end
  end
end
