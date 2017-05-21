Sequel.migration do
  up do
    alter_table(:versions) do
      # Not actually sure which index it will use for OrderVersions, so CREATE ALL THE INDEXES!
      add_index [:number], name: 'ndx_ver_num' # Not sure if this is useful give we use LIKE not EQ
      add_index [:order], name: 'ndx_ver_ord'
      add_index [:pacticipant_id, :order], name: 'ndx_ver_ppt_ord'
      add_index [:pacticipant_id, :order, :id], name: 'ndx_ver_ppt_ord_id'
      add_index [:created_at], name: 'ndx_ver_created'
      add_index [:created_at, :id], name: 'ndx_ver_created_id'
    end
  end
end
