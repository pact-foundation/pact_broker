require 'erb'

module PactBroker
  module UI
    module Helpers
      module URLHelper

        extend self

        def group_url pacticipant_name
          "/groups/#{ERB::Util.url_encode(pacticipant_name)}"
        end

      end
    end
  end
end
