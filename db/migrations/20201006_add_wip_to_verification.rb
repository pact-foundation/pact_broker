Sequel.migration do
  change do
    add_column(:verifications, :wip, TrueClass, default: false, null: false)
  end
end
