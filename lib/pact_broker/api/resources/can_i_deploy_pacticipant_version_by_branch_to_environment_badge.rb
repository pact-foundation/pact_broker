require "pact_broker/api/resources/can_i_deploy_pacticipant_version_by_branch_to_environment"

module PactBroker
  module Api
    module Resources
      class CanIDeployPacticipantVersionByBranchToEnvironmentBadge < CanIDeployPacticipantVersionByBranchToEnvironment
        include BadgeMethods

        private

        def badge_url
          if pacticipant && version && environment
            badge_service.can_i_deploy_badge_url(identifier_from_path[:branch_name], identifier_from_path[:environment_name], label, results.deployable?)
          elsif pacticipant.nil?
            badge_service.error_badge_url("pacticipant", "not found")
          elsif version.nil?
            if branch_service.find_branch(identifier_from_path.slice(:pacticipant_name, :branch_name)).nil?
              badge_service.error_badge_url("branch", "not found")
            else
              badge_service.error_badge_url("version", "not found")
            end
          else
            badge_service.error_badge_url("environment", "not found")
          end
        end
      end
    end
  end
end
