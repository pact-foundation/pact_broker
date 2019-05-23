Sequel.migration do
  change do
    add_column(:webhooks, :description, String)
  end
end
