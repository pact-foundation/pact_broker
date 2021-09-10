require "erb"

module PactBroker
  module UI
    module Helpers
      module URLHelper

        extend self

        def group_url pacticipant_name, base_url = ""
          "#{base_url}/pacticipants/#{ERB::Util.url_encode(pacticipant_name)}"
        end

        def matrix_url consumer_name, provider_name, base_url = ""
          "#{base_url}/matrix/provider/#{ERB::Util.url_encode(provider_name)}/consumer/#{ERB::Util.url_encode(consumer_name)}"
        end
      end
    end
  end
end
