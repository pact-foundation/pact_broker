Sequel.migration do
  up do
    transaction do
      drop_view :integrations
      rename_table :temp_integrations, :integrations
    end
  end

  down do
    rename_table :integrations, :temp_integrations
    create_view(:integrations,
      from(:pact_publications)
        .select(
          :consumer_id,
          Sequel[:c][:name].as(:consumer_name),
          :provider_id,
          Sequel[:p][:name].as(:provider_name)
        ).distinct
        .join(:pacticipants, {:id => :consumer_id}, {:table_alias => :c, implicit_qualifier: :pact_publications})
        .join(:pacticipants, {:id => :provider_id}, {:table_alias => :p, implicit_qualifier: :pact_publications})
    )
  end
end
