require "pact_broker/db"
require "pact_broker/repositories/helpers"

module PactBroker
  module Versions
    class BranchHead < Sequel::Model
      plugin :upsert, identifying_columns: [:branch_id]
      set_primary_key :branch_id
      unrestrict_primary_key

      associate(:many_to_one, :branch, :class => "PactBroker::Versions::Branch", :key => :branch_id, :primary_key => :id)
      associate(:many_to_one, :branch_version, :class => "PactBroker::Versions::BranchVersion", :key => :branch_version_id, :primary_key => :id)
      associate(:many_to_one, :version, :class => "PactBroker::Domain::Version", :key => :version_id, :primary_key => :id)

      def before_save
        super
        self.pacticipant_id = branch.pacticipant_id
        self.version_id = branch_version.version_id
        self.branch_name = branch.name
      end

      def branch_name
        branch.name
      end
    end
  end
end

# Table: branch_heads
# Columns:
#  branch_id         | integer | NOT NULL
#  branch_version_id | integer | NOT NULL
#  version_id        | integer | NOT NULL
#  pacticipant_id    | integer | NOT NULL
#  branch_name       | text    | NOT NULL
# Indexes:
#  branch_heads_branch_id_index      | UNIQUE btree (branch_id)
#  branch_heads_branch_name_index    | btree (branch_name)
#  branch_heads_pacticipant_id_index | btree (pacticipant_id)
#  branch_heads_version_id_index     | btree (version_id)
# Foreign key constraints:
#  branch_heads_branch_id_fkey         | (branch_id) REFERENCES branches(id) ON DELETE CASCADE
#  branch_heads_branch_version_id_fkey | (branch_version_id) REFERENCES branch_versions(id) ON DELETE CASCADE
