Sequel.migration do
  change do
    add_column(:pacts, :created_at, DateTime)
    add_column(:pacts, :updated_at, DateTime)
    add_column(:tags, :created_at, DateTime)
    add_column(:tags, :updated_at, DateTime)
    add_column(:versions, :created_at, DateTime)
    add_column(:versions, :updated_at, DateTime)
    add_column(:pacticipants, :created_at, DateTime)
    add_column(:pacticipants, :updated_at, DateTime)
  end
end
