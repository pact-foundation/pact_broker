Sequel.migration do
  up do
    from(:triggered_webhooks).where(trigger_type: 'pact_publication').update(trigger_type: 'publication')
  end

  down do
    from(:triggered_webhooks).where(trigger_type: 'publication').update(trigger_type: 'pact_publication')
  end
end
