require_relative "../ddl_statements/all_verifications"

# Naughtily insert this migration file after the creation of 20211104_switch_integrations_and_temp_integrations.rb
# to fix the all_verifications view before
# dropping the columns in 20210702_drop_unused_columns_from_deployed_versions.rb.
# The update to all_verifications was already applied in
# 20211101_recreate_all_verifications.rb, but some versions of SQLite error
# if the view is not updated first, meaning 20210702 was never run.
# It won't matter if this update runs out of order, as long as it's after
# 20210117_add_branch_to_version.rb
Sequel.migration do
  up do
    create_or_replace_view(:all_verifications, all_verifications_v2(self))
  end

  down do
  end
end
