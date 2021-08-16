require "pact_broker/db"
require "pact_broker/repositories/helpers"

module PactBroker
  module Versions
    class BranchHead < Sequel::Model
      plugin :upsert, identifying_columns: [:branch_id]

      associate(:many_to_one, :branch, :class => "PactBroker::Versions::Branch", :key => :branch_id, :primary_key => :id)
      associate(:many_to_one, :branch_version, :class => "PactBroker::Versions::BranchVersion", :key => :branch_version_id, :primary_key => :id)
      associate(:many_to_one, :version, :class => "PactBroker::Domain::Version", :key => :version_id, :primary_key => :id)

      def before_save
        super
        self.pacticipant_id = branch.pacticipant_id
        self.version_id = branch_version.version_id
      end

      def branch_name
        branch.name
      end
    end
  end
end
