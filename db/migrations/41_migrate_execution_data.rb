require 'securerandom'

Sequel.migration do
  up do
    from(:webhook_executions).each do | execution |
      pact_publication = from(:all_pact_publications).where(
        consumer_id: execution[:consumer_id],
        provider_id: execution[:provider_id]
      ).where(
        Sequel.lit("created_at <= ?", execution[:created_at])
      ).reverse_order(:id).limit(1).single_record

      if pact_publication && execution[:webhook_id]
        webhook = from(:webhooks).where(id: execution[:webhook_id]).single_record

        if webhook
          webhook_uuid = webhook[:uuid]
          status = execution[:success] ? 'success' : 'failure'

          from(:triggered_webhooks).insert(
            trigger_uuid: SecureRandom.urlsafe_base64,
            trigger_type: 'pact_publication',
            pact_publication_id: pact_publication[:id],
            webhook_id: execution[:webhook_id],
            webhook_uuid: webhook_uuid,
            consumer_id: execution[:consumer_id],
            provider_id: execution[:provider_id],
            created_at: execution[:created_at],
            updated_at: execution[:created_at],
            status: status
          )
        end
      end
      from(:webhook_executions)
        .where(id: execution[:id])
        .update(
          webhook_id: nil,
          consumer_id: nil,
          provider_id: nil,
          pact_publication_id: nil)
    end
  end

  down do
    from(:triggered_webhooks).delete
  end
end
