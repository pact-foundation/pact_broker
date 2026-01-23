Sequel.migration do
  up do
    if !mysql?
      alter_table(:branch_versions) do
        drop_index([:branch_name], name: "branch_versions_branch_name_index")
      end
    end
  end

  down do
    if !mysql?
      alter_table(:branch_versions) do
        add_index([:branch_name], name: "branch_versions_branch_name_index")
      end
    end
  end
end
