Sequel.migration do
  up do
    alter_table(:pacticipants) do
      add_column(:main_branch, String)
      drop_column(:main_development_branches)
    end
  end

  down do
    alter_table(:pacticipants) do
      drop_column(:main_branch)
      add_column(:main_development_branches, String)
    end
  end
end
