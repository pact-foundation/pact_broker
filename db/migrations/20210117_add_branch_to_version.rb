Sequel.migration do
  change do
    alter_table(:versions) do
      add_column(:branch, String)
      add_column(:build_url, String)
      add_index([:pacticipant_id, :branch, :order], name: "versions_pacticipant_id_branch_order_index")
    end
  end
end
