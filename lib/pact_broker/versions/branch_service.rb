require "pact_broker/logging"
require "pact_broker/repositories"
require "pact_broker/messages"
require "forwardable"

module PactBroker
  module Versions
    class BranchService
      extend PactBroker::Repositories

      class << self
        extend Forwardable
        delegate [:delete_branch_version] => :branch_version_repository
      end


      def self.find_branch_version(pacticipant_name:, branch_name:, version_number:, **)
        BranchVersion.where(
          version: PactBroker::Domain::Version.where_pacticipant_name_and_version_number(pacticipant_name, version_number),
          branch: Branch.where(name: branch_name)
        ).single_record
      end

      def self.find_or_create_branch_version(pacticipant_name:, branch_name:, version_number:, **)
        pacticipant = pacticipant_repository.find_by_name_or_create(pacticipant_name)
        version = version_repository.find_by_pacticipant_id_and_number_or_create(pacticipant.id, version_number)
        branch_version_repository.add_branch(version, branch_name)
      end

      def self.find_branch(pacticipant_name:, branch_name:)
        Branch
          .select_all_qualified
          .join(:pacticipants, { Sequel[:branches][:pacticipant_id] => Sequel[:pacticipants][:id] }) do
            Sequel.name_like(Sequel[:pacticipants][:name], pacticipant_name)
          end
          .where(Sequel[:branches][:name] => branch_name)
          .single_record
      end
    end
  end
end
