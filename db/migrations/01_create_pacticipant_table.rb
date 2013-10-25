Sequel.migration do
  change do
    create_table(:pacticipants) do
      primary_key :id
      String :name, :unique => true
      String :repository_url
    end
  end
end