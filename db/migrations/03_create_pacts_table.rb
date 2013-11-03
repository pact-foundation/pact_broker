Sequel.migration do
  change do
    create_table(:pacts) do
      primary_key :id
      String :json_content, :text=>true
      foreign_key :version_id, :versions, null: false
      foreign_key :provider_id, :pacticipants, null: false
      index [:version_id, :provider_id], :unique=>true
    end
  end
end

