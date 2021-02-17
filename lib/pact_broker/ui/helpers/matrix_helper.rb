module PactBroker
  module UI
    module Helpers
      module MatrixHelper

        extend self

        def create_selector_objects(selector_hashes)
          selector_hashes.collect do | selector_hash |
            o = OpenStruct.new(selector_hash)
            o.specify_latest_tag = o.tag && o.latest ? 'checked' : nil
            o.specify_latest_branch = o.branch && o.latest ? 'checked' : nil
            o.specify_all_tagged = o.tag && !o.latest ? 'checked' : nil
            o.specify_latest = o.latest ? 'checked' : nil
            o.specify_version = o.pacticipant_version_number ? 'checked' : nil
            o.specify_all_versions = !(o.tag || o.pacticipant_version_number || o.branch) ? 'checked' : nil
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

        def matrix_badge_url(selectors, lines, base_url)
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
