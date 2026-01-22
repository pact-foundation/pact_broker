Sequel.migration do
  up do
    if !mysql?
      alter_table(:pact_versions) do
        add_index :consumer_id, name: :pact_versions_consumer_id_index
        add_index :provider_id, name: :pact_versions_provider_id_index
      end
    end
  end

  down do
    if !mysql?
      alter_table(:pact_versions) do
        drop_index :consumer_id, name: :pact_versions_consumer_id_index
        drop_index :provider_id, name: :pact_versions_provider_id_index
      end
    end
  end
end

