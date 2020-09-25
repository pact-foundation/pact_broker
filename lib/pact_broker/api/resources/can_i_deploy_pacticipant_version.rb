require 'pact_broker/api/resources/matrix'
require 'pact_broker/matrix/can_i_deploy_query_schema'
require 'pact_broker/matrix/parse_can_i_deploy_query'

module PactBroker
  module Api
    module Resources
      class CanIDeployPacticipantVersion < Matrix
        def initialize
          super
          selector = PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: pacticipant_name, latest: true, tag: identifier_from_path[:tag])
          @options = {
            latestby: 'cvp',
            latest: true,
            tag: identifier_from_path[:to]
          }
          @selectors = [selector]
        end

        def resource_exists?
          !!version
        end

        def policy_name
          :'matrix::can_i_deploy'
        end

        private

        def version
          @version ||= version_service.find_by_pacticipant_name_and_latest_tag(identifier_from_path[:pacticipant_name], identifier_from_path[:tag])
        end

        def results
          @results ||= matrix_service.find(selectors, options)
        end
      end
    end
  end
end
