require_relative "../ddl_statements"
require_relative "migration_helper"

include PactBroker::MigrationHelper

Sequel.migration do
  up do
    create_or_replace_view(:head_pact_tags, head_pact_tags_v2(self))
  end

  down do
    create_or_replace_view(:head_pact_tags, head_pact_tags_v2_rollback(self, postgres?))
  end
end
