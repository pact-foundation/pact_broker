require "pact_broker/db"
require "pact_broker/repositories/helpers"

module PactBroker
  module Versions
    class BranchVersion < Sequel::Model(:branch_versions)
      plugin :timestamps, update_on_create: true
      plugin :insert_ignore, identifying_columns: [:branch_id, :version_id]

      associate(:many_to_one, :branch, :class => "PactBroker::Versions::Branch", :key => :branch_id, :primary_key => :id)
      associate(:many_to_one, :version, :class => "PactBroker::Domain::Version", :key => :version_id, :primary_key => :id)

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

        if version_order.nil? || pacticipant_id.nil?
          raise PactBroker::Error.new("Need to set version_order and pacticipant_id for tags now")
        end
      end

      def branch_name
        branch.name
      end
    end
  end
end
