require "pact_broker/matrix/can_i_deploy_query_schema"
require "pact_broker/matrix/parse_can_i_deploy_query"
require "pact_broker/api/resources/badge_methods"

module PactBroker
  module Api
    module Resources
      class CanIDeployBadge < BaseResource
        include BadgeMethods
        def initialize
          super
          selector = PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: pacticipant_name, latest: true, tag: identifier_from_path[:tag])
          @options = {
            latestby: "cvp",
            latest: true,
            tag: identifier_from_path[:to]
          }
          @selectors = [selector]
        end

        def badge_url
          if pacticipant
            if version
              badge_service.can_i_deploy_badge_url(identifier_from_path[:tag], identifier_from_path[:to], label, results.deployable?)
            else
              badge_service.error_badge_url("version", "not found")
            end
          else
            badge_service.error_badge_url(selectors.first.pacticipant_name, "not found")
          end
        end

        private

        attr_reader :selectors, :options

        def results
          @results ||= matrix_service.can_i_deploy(selectors, options)
        end

        def version
          @version ||= version_service.find_by_pacticipant_name_and_latest_tag(identifier_from_path[:pacticipant_name], identifier_from_path[:tag])
        end

        def label
          lab = request.query["label"]
          lab && !lab.empty? ? lab : nil
        end
      end
    end
  end
end
