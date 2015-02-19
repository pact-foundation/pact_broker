require 'webmachine'

module PactBroker
  module Diagnostic
    module Resources
      class Heartbeat < Webmachine::Resource

        def allowed_methods
          ["GET"]
        end

        def content_types_provided
          [["application/json+hal", :to_json]]
        end

        def to_json
          {
            "ok" => true,
            "_links" => {
              "self" => {
                "href" => request.uri.to_s
              }
            }
          }.to_json
        end

      end
    end
  end
end
