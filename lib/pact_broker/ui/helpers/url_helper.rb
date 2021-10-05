require "erb"

module PactBroker
  module UI
    module Helpers
      module URLHelper

        extend self

        def dashboard_url consumer_name, provider_name, base_url = ""
          "#{base_url}/dashboard/provider/#{provider_name}/consumer/#{consumer_name}"
        end

        def group_url pacticipant_name, base_url = ""
          "#{base_url}/pacticipants/#{ERB::Util.url_encode(pacticipant_name)}"
        end

        def matrix_url consumer_name, provider_name, base_url = ""
          "#{base_url}/matrix/provider/#{ERB::Util.url_encode(provider_name)}/consumer/#{ERB::Util.url_encode(consumer_name)}"
        end

        def matrix_url_for_consumer_version consumer_name, consumer_version_number, provider_name, base_url = ""
          query = {
            q:
            [
              { pacticipant: consumer_name, version: consumer_version_number },
              { pacticipant: provider_name }
            ],
            latestby: "cvpv"
          }
          "#{base_url}/matrix?" + Rack::Utils.build_nested_query(query)
        end
      end
    end
  end
end
