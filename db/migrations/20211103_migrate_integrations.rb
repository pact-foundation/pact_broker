Sequel.migration do
  up do
    from(:temp_integrations).insert(
      [:consumer_id, :consumer_name, :provider_id, :provider_name],
      from(:integrations).select(:consumer_id, :consumer_name, :provider_id, :provider_name)
    )
  end

  down do

  end
end
