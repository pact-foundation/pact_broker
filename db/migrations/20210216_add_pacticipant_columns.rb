Sequel.migration do
  change do
    update_table(:pacticipants, charset: 'utf8') do
      add_column(:display_name, String)
      add_column(:repository_name, String)
      add_column(:repository_organization, String)
    end
  end
end
