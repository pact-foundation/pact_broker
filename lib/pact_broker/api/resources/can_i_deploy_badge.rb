require "pact_broker/matrix/can_i_deploy_query_schema"
require "pact_broker/matrix/parse_can_i_deploy_query"

module PactBroker
  module Api
    module Resources
      class CanIDeployBadge < BaseResource
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

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def content_types_provided
          [["image/svg+xml", :to_svg]]
        end

        def resource_exists?
          false
        end

        # Only called if resource_exists? returns false
        def previously_existed?
          true
        end

        def is_authorized?(authorization_header)
          super || PactBroker.configuration.enable_public_badge_access
        end

        def forbidden?
          false
        end

        def moved_temporarily?
          response.headers["Cache-Control"] = "no-cache"
          begin
            if pacticipant
              if version
                badge_service.can_i_deploy_badge_url(identifier_from_path[:tag], identifier_from_path[:to], label, results.deployable?)
              else
                badge_service.error_badge_url("version", "not found")
              end
            else
              badge_service.error_badge_url(selectors.first.pacticipant_name, "not found")
            end
          rescue StandardError => e
            # Want to render a badge, even if there's an error
            badge_service.error_badge_url("error", ErrorResponseBodyGenerator.display_message(e, "reference: #{PactBroker::Errors.generate_error_reference}"))
          end
        end

        def policy_name
          :'badges::badge'
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
