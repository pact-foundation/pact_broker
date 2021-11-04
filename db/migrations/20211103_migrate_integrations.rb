Sequel.migration do
  up do
    from(:temp_integrations).insert(
      [:consumer_id, :consumer_name, :provider_id, :provider_name, :created_at],
      from(:pact_publications)
        .select(
          :consumer_id,
          Sequel[:c][:name].as(:consumer_name),
          :provider_id,
          Sequel[:p][:name].as(:provider_name),
          Sequel[:c][:created_at]
        ).distinct
        .join(:pacticipants, {:id => :consumer_id}, {:table_alias => :c, implicit_qualifier: :pact_publications})
        .join(:pacticipants, {:id => :provider_id}, {:table_alias => :p, implicit_qualifier: :pact_publications})
    )
  end

  down do

  end
end
