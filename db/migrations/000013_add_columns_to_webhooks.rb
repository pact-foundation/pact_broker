Sequel.migration do
  change do
    add_column(:webhooks, :created_at, DateTime)
    add_column(:webhooks, :updated_at, DateTime)
    add_column(:webhooks, :username, String)
    add_column(:webhooks, :password, String)
  end
end
