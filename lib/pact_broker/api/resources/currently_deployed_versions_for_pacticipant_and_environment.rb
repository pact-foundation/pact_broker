require 'pact_broker/api/resources/currently_deployed_versions_for_environment'

module PactBroker
  module Api
    module Resources
      class CurrentlyDeployedVersionsForPacticipantAndEnvironment < CurrentlyDeployedVersionsForEnvironment
        def resource_exists?
          !!pacticipant && !!environment
        end

        private

        def deployed_versions
          @deployed_versions ||= deployed_version_service.find_currently_deployed_versions_for_pacticipant_and_environment(pacticipant, environment, query)
        end

        def title
          "Deployed versions for #{pacticipant.display_name} in #{environment.display_name}"
        end

        def query
          if request.query.any?
            {
              pacticipant_version_number: request.query["version"]
            }.compact
          else
            {}
          end
        end
      end
    end
  end
end
