Sequel.migration do
  up do
    create_table(:pact_version_provider_tag_successful_verifications, charset: "utf8") do
      primary_key :id
      foreign_key :pact_version_id, :pact_versions, null: false, on_delete: :cascade, foreign_key_constraint_name: "pact_version_provider_tag_successful_verifications_pact_version_id_fk"
      String :provider_version_tag_name, null: false
      Boolean :wip, null: false
      Integer :verification_id
      DateTime :execution_date, null: false
      index([:pact_version_id, :provider_version_tag_name, :wip], unique: true, name: "pact_version_provider_tag_verifications_pv_pvtn_wip_unique")
      # The implication of the on_delete: :set_null for verification_id is
      # that even if the verification result is deleted from the broker,
      # the wip/pending status stays the same.
      # We may or may not want this. Will have to wait and see.
      # Have made the foreign key a separate declaration so it can more easily be remade.
      foreign_key([:verification_id], :verifications, on_delete: :set_null, name: "pact_version_provider_tag_successful_verifications_verification_id_fk")
    end
  end

  down do
    drop_table(:pact_version_provider_tag_successful_verifications)
  end
end
