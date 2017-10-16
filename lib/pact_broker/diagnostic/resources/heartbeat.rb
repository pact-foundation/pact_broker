require 'pact_broker/diagnostic/resources/base_resource'

module PactBroker
  module Diagnostic
    module Resources
      class Heartbeat < BaseResource

        def allowed_methods
          ["GET"]
        end

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def to_json
          @@json ||= {
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
