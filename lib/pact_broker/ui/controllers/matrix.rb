require 'pact_broker/ui/controllers/base_controller'
require 'pact_broker/ui/view_models/matrix_line'
require 'pact_broker/matrix/parse_query'
require 'pact_broker/logging'
require 'haml'

module PactBroker
  module UI
    module Controllers
      class Matrix < Base

        include PactBroker::Services
        include PactBroker::Logging

        get "/" do
          selectors = [OpenStruct.new, OpenStruct.new]
          locals = {
            lines: [],
            title: "The Matrix",
            selectors: create_selector_objects(selectors)
          }
          begin
            if params[:q]
              selectors, options = PactBroker::Matrix::ParseQuery.call(request.env['QUERY_STRING'])
              locals[:selectors] = create_selector_objects(selectors)
              errors = matrix_service.validate_selectors(selectors)
              if errors.empty?
                lines = matrix_service.find(selectors, options)
                locals[:lines] = lines.collect{ |line| PactBroker::UI::ViewDomain::MatrixLine.new(line) }
              else
                locals[:errors] = errors
              end
            end
          rescue StandardError => e
            log_error(e) unless e.is_a?(PactBroker::Error)
            locals[:errors] = [e.message]
          end
          haml :'matrix/show', {locals: locals, layout: :'layouts/main'}
        end

        get "/provider/:provider_name/consumer/:consumer_name" do
          selectors = [{ pacticipant_name: params[:consumer_name] }, { pacticipant_name: params[:provider_name] } ]
          lines = matrix_service.find(selectors, {latestby: 'cvpv', limit: 1000})
          lines = lines.collect{ |line| PactBroker::UI::ViewDomain::MatrixLine.new(line) }.sort
          locals = {
            lines: lines,
            title: "The Matrix",
            consumer_name: params[:consumer_name],
            provider_name: params[:provider_name]
          }
          haml :'matrix/show', {locals: locals, layout: :'layouts/main'}
        end

        def create_selector_objects(selector_hashes)
          selector_hashes.collect do | selector_hash |
            o = OpenStruct.new(selector_hash)
            o.tag_disabled = o.tag ? nil : 'disabled'
            o.version_disabled = o.pacticipant_version_number ? nil : 'disabled'
            o.specify_latest_tag_checked = o.tag ? 'checked' : nil
            o.specify_version_checked = o.pacticipant_version_number ? 'checked' : nil
            o.specify_all_versions_checked = !(o.tag || o.pacticipant_version_number) ? 'checked' : nil
            o
          end
        end
      end
    end
  end
end
