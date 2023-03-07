require "pact_broker/api/resources/matrix"
require "pact_broker/matrix/can_i_deploy_query_schema"
require "pact_broker/matrix/parse_can_i_deploy_query"
require "pact_broker/api/decorators/matrix_decorator"
require "pact_broker/api/decorators/matrix_text_decorator"

module PactBroker
  module Api
    module Resources
      class CanIDeployPacticipantVersionByBranchToEnvironment < BaseResource
        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def content_types_provided
          [
            ["application/hal+json", :to_json],
            ["text/plain", :to_text]
          ]
        end

        def resource_exists?
          !!(version && environment)
        end

        def policy_name
          :'versions::version'
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

        def to_json
          decorator_class(:matrix_decorator).new(results).to_json(**decorator_options)
        end

        def results
          @results ||= matrix_service.can_i_deploy(selectors, options)
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
