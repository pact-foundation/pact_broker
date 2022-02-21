require "pact_broker/api/resources/matrix"
require "pact_broker/matrix/can_i_deploy_query_schema"
require "pact_broker/matrix/parse_can_i_deploy_query"

module PactBroker
  module Api
    module Resources
      class CanIDeployPacticipantVersionByBranchToEnvironment < Matrix
        def resource_exists?
          !!(version && environment)
        end

        def malformed_request?
          false
        end

        def policy_name
          :'matrix::can_i_deploy'
        end

        private

        def selectors
          @selectors ||= [
                            PactBroker::Matrix::UnresolvedSelector.new(
                              pacticipant_name: pacticipant_name,
                              latest: true,
                              branch: identifier_from_path[:branch_name]
                            )
                          ]
        end

        def options
          @options ||=  {
                          latestby: "cvp",
                          environment_name: identifier_from_path[:environment_name]
                        }
        end

        def version
          @version ||= version_service.find_latest_by_pacticipant_name_and_branch_name(identifier_from_path[:pacticipant_name], identifier_from_path[:branch_name])
        end

        def environment
          @environment ||= environment_service.find_by_name(identifier_from_path[:environment_name])
        end
      end
    end
  end
end
