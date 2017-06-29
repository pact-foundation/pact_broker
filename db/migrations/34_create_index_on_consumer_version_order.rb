Sequel.migration do
  change do
    alter_table(:versions) do
      # Not actually sure which index it will use for OrderVersions, so CREATE ALL THE INDEXES!
      add_index [:number], name: 'ndx_ver_num' # Not sure if this is useful give we use LIKE not EQ
      add_index [:order], name: 'ndx_ver_ord'
      add_index [:pacticipant_id, :order], unique: true, name: 'uq_ver_ppt_ord'
    end
  end
end
