Sequel.migration do
  change do
    alter_table(:versions) do
      add_index [:pacticipant_id, :order], unique: true, unique_constraint_name: 'uq_ver_ppt_ord'
    end
  end
end
