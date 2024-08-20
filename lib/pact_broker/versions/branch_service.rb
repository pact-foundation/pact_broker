require "forwardable"
require "pact_broker/logging"
require "pact_broker/repositories"
require "pact_broker/messages"
require "pact_broker/contracts/notice"

module PactBroker
  module Versions
    class BranchService
      extend PactBroker::Repositories
      extend PactBroker::Messages

      class << self
        extend Forwardable
        delegate [:find_branch_version, :find_or_create_branch_version, :delete_branch_version] => :branch_version_repository
        delegate [:find_branch, :delete_branch, :find_all_branches_for_pacticipant, :delete_branches_for_pacticipant] => :branch_repository

        # Returns a list of notices to display to the user in the terminal
        # @param [PactBroker::Domain::Pacticipant] pacticipant
        # @param [Array<String>] exclude the list of branches to NOT delete
        # @return [Array<PactBroker::Contracts::Notice>]
        def branch_deletion_notices(pacticipant, exclude:)
          count = branch_repository.count_branches_to_delete(pacticipant, exclude: exclude)
          remaining = branch_repository.remaining_branches_after_future_deletion(pacticipant, exclude: exclude).sort_by(&:created_at).collect(&:name).join(", ")
          [PactBroker::Contracts::Notice.success(message("messages.branch.bulk_delete", count: count, pacticipant_name: pacticipant.name, remaining: remaining))]
        end
      end
    end
  end
end
