Sequel.migration do
  up do
    alter_table(:pacticipants) do
      add_column(:main_branch, String)
    end

    # TODO
    # alter_table(:pacticipants) do
    #   drop_column(:main_development_branches)
    # end
  end

  down do
    alter_table(:pacticipants) do
      drop_column(:main_branch)
      # TODO
      # add_column(:main_development_branches, String)
    end

    # TODO
    # alter_table(:pacticipants) do
    #   add_column(:main_development_branches, String)
    # end
  end
end
