require "pact_broker/logging"
require "pact_broker/repositories"
require "pact_broker/messages"

module PactBroker
  module Versions
    class BranchService
      extend PactBroker::Repositories

      def self.find_branch_version(pacticipant_name:, branch_name:, version_number:, **)
        BranchVersion.where(
          version: PactBroker::Domain::Version.where_pacticipant_name_and_version_number(pacticipant_name, version_number),
          branch: Branch.where(name: branch_name)
        ).single_record
      end

      def self.find_or_create_branch_version(pacticipant_name:, branch_name:, version_number:, **)
        pacticipant = pacticipant_repository.find_by_name_or_create(pacticipant_name)
        version = version_repository.find_by_pacticipant_id_and_number_or_create(pacticipant.id, version_number)
        branch = Branch.find_or_create(pacticipant: pacticipant, name: branch_name)
        branch_version = BranchVersion.new(
          version: version,
          branch: branch
        ).upsert
        PactBroker::Versions::BranchHead.new(branch: branch, branch_version: branch_version).upsert
        branch_version
      end
    end
  end
end
