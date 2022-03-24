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
      class Matrix < Base

        include PactBroker::Services
        include PactBroker::UI::Helpers::MatrixHelper

        get "/" do
          selectors = [OpenStruct.new, OpenStruct.new]
          options = { limit: 100, latestby: nil }
          locals = {
            lines: [],
            selectors: create_selector_objects(selectors),
            options: create_options_model(options),
            base_url: base_url
          }
          begin
            if params[:q]
              selectors, options = PactBroker::Matrix::ParseQuery.call(request.env["QUERY_STRING"])
              locals[:selectors] = create_selector_objects(selectors)
              locals[:options] = create_options_model(options)
              errors = matrix_service.validate_selectors(selectors, options)
              if errors.empty?
                lines = matrix_service.find(selectors, options)
                locals[:lines] = PactBroker::UI::ViewDomain::MatrixLines.new(lines, base_url: base_url)
                locals[:badge_url] = matrix_badge_url(selectors, lines, base_url)
              else
                locals[:errors] = errors
              end
            end
          rescue StandardError => e
            Padrino.logger.exception(e) unless e.is_a?(PactBroker::Error)
            locals[:errors] = [e.message]
          end
          haml :'matrix/show', { locals: locals, layout: :'layouts/main', escape_html: true }
        end

        get "/provider/:provider_name/consumer/:consumer_name" do
          selectors = [
                        PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: params[:consumer_name]),
                        PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: params[:provider_name])
                      ]
          options = { latestby: "cvpv", limit: 100 }
          lines = matrix_service.find(selectors, options)
          lines = PactBroker::UI::ViewDomain::MatrixLines.new(lines, base_url: base_url)
          locals =  {
                      lines: lines,
                      consumer_name: params[:consumer_name],
                      provider_name: params[:provider_name],
                      selectors: create_selector_objects(selectors),
                      options: create_options_model(options),
                      badge_url: nil,
                      base_url: base_url
                    }
          haml :'matrix/show', { locals: locals, layout: :'layouts/main', escape_html: true }
        end
      end
    end
  end
end
