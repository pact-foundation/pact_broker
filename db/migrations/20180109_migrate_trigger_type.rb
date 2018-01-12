Sequel.migration do
  up do
    from(:triggered_webhooks).where(trigger_type: 'pact_publication').update(trigger_type: 'resource_creation')
  end

  down do
    from(:triggered_webhooks).where(trigger_type: 'resource_creation').update(trigger_type: 'pact_publication')
  end
end
