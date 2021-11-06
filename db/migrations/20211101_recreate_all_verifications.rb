require_relative "../ddl_statements/all_verifications"

Sequel.migration do
  up do
    create_or_replace_view(:all_verifications, all_verifications_v2(self))
  end

  down do
  end
end
