Sequel.migration do
  change do
    create_table(:pacts) do
      primary_key :id
      String :json_content
      foreign_key :provider_id, :pacticipants
    end
  end
end

