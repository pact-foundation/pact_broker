Sequel.migration do
  up do
    PactBroker::MigrationHelper.with_mysql do
      run("SET FOREIGN_KEY_CHECKS = 0")
    end

    alter_table(:pact_versions) do
      set_column_not_null(:consumer_id)
      set_column_not_null(:provider_id)
    end

    PactBroker::MigrationHelper.with_mysql do
      run("SET FOREIGN_KEY_CHECKS = 1")
    end
  end
end
