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
        delegate [:find_branch_version, :find_or_create_branch_version, :delete_branch_version] => :branch_version_repository
        delegate [:find_branch, :delete_branch, :find_all_branches_for_pacticipant] => :branch_repository
      end
    end
  end
end
