Sequel.migration do
  change do
    alter_table(:pacticipants) do
      add_index [:name], name: 'ndx_ppt_name' # Not sure if this is useful give we use LIKE not EQ
    end

    alter_table(:tags) do
      add_index [:name], name: 'ndx_tag_name' # Not sure if this is useful give we use LIKE not EQ
    end
  end
end
