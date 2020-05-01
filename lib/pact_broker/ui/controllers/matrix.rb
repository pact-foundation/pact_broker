require 'pact_broker/ui/controllers/base_controller'
require 'pact_broker/ui/view_models/matrix_lines'
require 'pact_broker/matrix/unresolved_selector'
require 'pact_broker/matrix/parse_query'
require 'pact_broker/logging'
require 'pact_broker/api/pact_broker_urls'

require 'haml'

module PactBroker
  module UI
    module Controllers
      class Matrix < Base

        include PactBroker::Services

        get "/" do
          selectors = [OpenStruct.new, OpenStruct.new]
          options = { limit: 100, latestby: nil }
          locals = {
            lines: [],
            title: "The Matrix",
            selectors: create_selector_objects(selectors),
            options: create_options_model(options)
          }
          begin
            if params[:q]
              selectors, options = PactBroker::Matrix::ParseQuery.call(request.env['QUERY_STRING'])
              locals[:selectors] = create_selector_objects(selectors)
              locals[:options] = create_options_model(options)
              errors = matrix_service.validate_selectors(selectors)
              if errors.empty?
                lines = matrix_service.find(selectors, options)
                locals[:lines] = PactBroker::UI::ViewDomain::MatrixLines.new(lines)
                locals[:badge_url] = matrix_badge_url(selectors, lines)
              else
                locals[:errors] = errors
              end
            end
          rescue StandardError => e
            Padrino.logger.exception(e) unless e.is_a?(PactBroker::Error)
            locals[:errors] = [e.message]
          end
          haml :'matrix/show', {locals: locals, layout: :'layouts/main'}
        end

        get "/provider/:provider_name/consumer/:consumer_name" do
          selectors = [ PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: params[:consumer_name]), PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: params[:provider_name]) ]
          options = {latestby: 'cvpv', limit: 100}
          lines = matrix_service.find(selectors, options)
          lines = PactBroker::UI::ViewDomain::MatrixLines.new(lines)
          locals = {
            lines: lines,
            title: "The Matrix",
            consumer_name: params[:consumer_name],
            provider_name: params[:provider_name],
            selectors: create_selector_objects(selectors),
            options: create_options_model(options),
            badge_url: nil
          }
          haml :'matrix/show', {locals: locals, layout: :'layouts/main'}
        end

        def create_selector_objects(selector_hashes)
          selector_hashes.collect do | selector_hash |
            o = OpenStruct.new(selector_hash)
            o.specify_latest_tag = o.tag && o.latest ? 'checked' : nil
            o.specify_all_tagged = o.tag && !o.latest ? 'checked' : nil
            o.specify_latest = o.latest ? 'checked' : nil
            o.specify_version = o.pacticipant_version_number ? 'checked' : nil
            o.specify_all_versions = !(o.tag || o.pacticipant_version_number) ? 'checked' : nil
            o
          end
        end

        def create_options_model(options)
          o = OpenStruct.new(options)
          o.cvpv_checked = o.latestby == 'cvpv' ? 'checked' : nil
          o.cvp_checked = o.latestby == 'cvp' ? 'checked' : nil
          o.all_rows_checked = o.latestby.nil? ? 'checked' : nil
          o
        end

        def matrix_badge_url(selectors, lines)
          if lines.any? && selectors.size == 2 && selectors.all?{ | selector| selector.latest_for_pacticipant_and_tag? }
            consumer_selector = selectors.find{ | selector| selector.pacticipant_name == lines.first.consumer_name }
            provider_selector = selectors.find{ | selector| selector.pacticipant_name == lines.first.provider_name }
            if consumer_selector && provider_selector
              PactBroker::Api::PactBrokerUrls.matrix_badge_url_for_selectors(consumer_selector, provider_selector, base_url)
            end
          end
        end
      end
    end
  end
end
