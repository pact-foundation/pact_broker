Sequel.migration do
  change do
    # TODO delete webhook headers table
    add_column(:webhooks, :headers, String)
  end
end
