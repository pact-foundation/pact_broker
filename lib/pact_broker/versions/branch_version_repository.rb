module PactBroker
  module Versions
    class BranchVersionRepository
      include PactBroker::Services

      def add_branch(version, branch_name, auto_created: false)
        branch = find_or_create_branch(version.pacticipant, branch_name)
        branch_version = version.branch_version_for_branch(branch)
        if branch_version
          branch_version.update(updated_at: Sequel.datetime_class.now)
        else
          branch_version = PactBroker::Versions::BranchVersion.new(version: version, branch: branch, auto_created: auto_created).insert_ignore
          PactBroker::Versions::BranchHead.new(branch: branch, branch_version: branch_version).upsert
        end
        pacticipant_service.maybe_set_main_branch(version.pacticipant, branch_name)
        branch_version
      end

      private

      def find_or_create_branch(pacticipant, branch_name)
        find_branch(pacticipant, branch_name) || create_branch(pacticipant, branch_name)
      end

      def find_branch(pacticipant, branch_name)
        PactBroker::Versions::Branch.where(pacticipant: pacticipant, name: branch_name).single_record
      end

      def create_branch(pacticipant, branch_name)
        PactBroker::Versions::Branch.new(pacticipant: pacticipant, name: branch_name).insert_ignore
      end
    end
  end
end
