Sequel.migration do
  up do
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

  down do
    drop_view(:integrations)
  end
end
