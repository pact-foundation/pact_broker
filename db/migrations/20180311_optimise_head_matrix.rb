require_relative "migration_helper"
require_relative "../ddl_statements"

Sequel.migration do
  up do
    # For each consumer_id/provider_id/tag_name, the version order of the latest version that has a pact
    create_or_replace_view(:latest_tagged_pact_consumer_version_orders,
      latest_tagged_pact_consumer_version_orders_v2(self))

    # Add provider_version_order to original definition
    # The most recent verification for each pact_version
    # provider_version column is DEPRECATED, use provider_version_number
    # Think this can be replaced by latest_verification_id_for_pact_version_and_provider_version?
    v = :verifications
    create_or_replace_view(:latest_verifications,
      from(v)
        .select(
          Sequel[v][:id],
          Sequel[v][:number],
          Sequel[v][:success],
          Sequel[:s][:number].as(:provider_version),
          Sequel[v][:build_url],
          Sequel[v][:pact_version_id],
          Sequel[v][:execution_date],
          Sequel[v][:created_at],
          Sequel[v][:provider_version_id],
          Sequel[:s][:number].as(:provider_version_number),
          Sequel[:s][:order].as(:provider_version_order))
        .join(:latest_verification_numbers,
          {
            Sequel[v][:pact_version_id] => Sequel[:lv][:pact_version_id],
            Sequel[v][:number] => Sequel[:lv][:latest_number]
          }, { table_alias: :lv })
        .join(:versions,
          {
            Sequel[v][:provider_version_id] => Sequel[:s][:id]
          }, { table_alias: :s })
    )

    create_or_replace_view(:head_matrix, HEAD_MATRIX_V1)
  end
end
