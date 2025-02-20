Sequel.migration do
  change do
    add_column(:verifications, :verified_by_client_implementation, String)
    add_column(:verifications, :verified_by_client_version, String)
    add_column(:verifications, :verified_by_client_test_framework, String)
  end
end
