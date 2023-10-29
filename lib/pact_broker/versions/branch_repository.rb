require "pact_broker/repositories/scopes"
module PactBroker
  module Versions
    class BranchRepository
      include PactBroker::Services
      include PactBroker::Repositories::Scopes

      # @param [PactBroker::Domain::Pacticipant] pacticipant
      # @param [Hash] filter_options with key :query_string
      # @param [Hash] pagination_options with keys :page_size and :page_number
      # @param [Array] eager_load_associations the associations to eager load
      def find_all_branches_for_pacticipant(pacticipant, filter_options = {}, pagination_options = {}, eager_load_associations = [])
        query = scope_for(Branch).where(pacticipant_id: pacticipant.id).select_all_qualified
        query = query.filter(:name, filter_options[:query_string]) if filter_options[:query_string]
        query
          .order(Sequel.desc(:created_at), Sequel.desc(:id))
          .eager(*eager_load_associations)
          .all_with_pagination_options(pagination_options)
      end

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

      def delete_branch_and_associated_versions(branch)
        branch.delete
      end
    end
  end
end
