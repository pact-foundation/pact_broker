require "pact_broker/db"
require "pact_broker/repositories/helpers"

module PactBroker
  module Versions
    class BranchVersion < Sequel::Model(:branch_versions)
      plugin :timestamps, update_on_create: true
      plugin :insert_ignore, identifying_columns: [:branch_id, :version_id]

      associate(:many_to_one, :branch, :class => "PactBroker::Versions::Branch", :key => :branch_id, :primary_key => :id)
      associate(:many_to_one, :version, :class => "PactBroker::Domain::Version", :key => :version_id, :primary_key => :id)

      dataset_module do
        def find_latest_for_branch(branch)
          max_version_order = BranchVersion.select(Sequel.function(:max, :version_order)).where(branch_id: branch.id)
          BranchVersion.where(branch_id: branch.id, version_order: max_version_order).single_record
        end
      end

      def before_save
        super

        if version.order && self.version_order.nil?
          self.version_order = version.order
        end

        if self.pacticipant_id.nil?
          if version.pacticipant_id
            self.pacticipant_id = version.pacticipant_id
          elsif version&.pacticipant&.id
            self.pacticipant_id = version.pacticipant.id
          end
        end

        self.branch_name = branch.name
      end
    end
  end
end
