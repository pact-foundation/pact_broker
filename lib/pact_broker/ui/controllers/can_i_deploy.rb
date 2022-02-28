require "pact_broker/ui/controllers/base_controller"
require "pact_broker/ui/view_models/matrix_lines"
require "pact_broker/matrix/unresolved_selector"
require "pact_broker/matrix/parse_query"
require "pact_broker/logging"
require "pact_broker/api/pact_broker_urls"
require "pact_broker/ui/helpers/matrix_helper"
require "haml"

module PactBroker
  module UI
    module Controllers
      class CanIDeploy < Base

        include PactBroker::Services
        include PactBroker::UI::Helpers::MatrixHelper

        get "/:pacticipant_name/latest-version/:tag/can-i-deploy/to/:environment_tag" do
          # selector and options must be in sync with lib/pact_broker/api/resources/can_i_deploy_pacticipant_version_by_tag_to_tag_badge.rb
          selectors = [ PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: params[:pacticipant_name], latest: true, tag: params[:tag]) ]
          options = { latestby: "cvp", limit: 100, tag: params[:to] }
          result = matrix_service.find(selectors, options)
          lines = PactBroker::UI::ViewDomain::MatrixLines.new(result, base_url: base_url)
          locals = {
            lines: lines,
            selectors: create_selector_objects(selectors),
            options: create_options_model(options),
            badge_url: badge_url,
            base_url: base_url
          }
          haml :'matrix/show', { locals: locals, layout: :'layouts/main', escape_html: true }
        end

        def badge_url
          u = URI(request.url)
          u.path = u.path + "/badge"
          u.to_s
        end
      end
    end
  end
end
