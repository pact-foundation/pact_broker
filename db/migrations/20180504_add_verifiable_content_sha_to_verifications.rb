Sequel.migration do
  change do
    alter_table(:verifications) do
      add_foreign_key(:consumer_id, :pacticipants, null: true)
      add_foreign_key(:provider_id, :pacticipants, null: true)
      add_column(:pact_verifiable_content_sha, String, null: true)
      # TODO make consumer_id not null
      # TODO make provider_id not null
      # TODO make pact_verifiable_content_sha not null
    end
  end
end
