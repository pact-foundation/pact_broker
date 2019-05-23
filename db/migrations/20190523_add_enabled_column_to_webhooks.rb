Sequel.migration do
  change do
    add_column(:webhooks, :enabled, TrueClass, default: true)
  end
end
