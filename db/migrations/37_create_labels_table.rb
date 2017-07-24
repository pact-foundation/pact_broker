Sequel.migration do
  change do
    create_table(:labels, charset: 'utf8') do
      String :name
      foreign_key :pacticipant_id, :pacticipants
      primary_key [:pacticipant_id, :name], name: :labels_pk
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
