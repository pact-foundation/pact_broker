Sequel.migration do
  up do
    alter_table(:versions) do
      drop_index [:pacticipant_id, :order], name: 'ndx_ver_ppt_ord'
      drop_index [:pacticipant_id, :order, :id], name: 'ndx_ver_ppt_ord_id'
      drop_index [:created_at], name: 'ndx_ver_created'
      drop_index [:created_at, :id], name: 'ndx_ver_created_id'
    end
  end
end
