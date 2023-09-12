module PactBroker
  module Versions
    class BranchRepository
      include PactBroker::Services

      # @param [String] pacticipant_name
      # @param [String] branch_name
      # @return [PactBroker::Versions::Branch, nil]
      def find_branch(pacticipant_name:, branch_name:)
        Branch
          .select_all_qualified
          .join(:pacticipants, { Sequel[:branches][:pacticipant_id] => Sequel[:pacticipants][:id] }) do
            Sequel.name_like(Sequel[:pacticipants][:name], pacticipant_name)
          end
          .where(Sequel[:branches][:name] => branch_name)
          .single_record
      end

      # Deletes a branch, its branch head and branch_version objects, without deleting the
      # pacticipant version objects
      #
      # @param [PactBroker::Versions::Branch] the branch to delete
      def delete_branch(branch)
        branch.delete
      end
    end
  end
end
