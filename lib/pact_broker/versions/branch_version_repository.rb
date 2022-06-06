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

      # Deletes a branch version - that is, removes a version from a branch.
      # Updates the branch head if the deleted branch version was the latest for the branch.
      #
      # @param [PactBroker::Versions::BranchVersion] the branch version to delete
      def delete_branch_version(branch_version)
        latest = branch_version.latest?
        branch = branch_version.latest? ? branch_version.branch : nil
        deleted = branch_version.delete
        if latest
          new_head_branch_version = BranchVersion.find_latest_for_branch(branch)
          if new_head_branch_version
            PactBroker::Versions::BranchHead.new(branch: branch, branch_version: new_head_branch_version).upsert
          end
        end
        deleted
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
