require 'webmachine'

module PactBroker
  module Diagnostic
    module Resources
      class Heartbeat < Webmachine::Resource

        def allowed_methods
          ["GET"]
        end

        def content_types_provided
          [["application/json", :to_json]]
        end

        def to_json
        end

      end
    end
  end
end
