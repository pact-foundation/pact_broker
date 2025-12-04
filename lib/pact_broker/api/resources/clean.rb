require "pact_broker/api/resources/base_resource"
require "pact_broker/db/clean"
require "pact_broker/matrix/unresolved_selector"

# Not exposed yet as we'd need to support administrator auth first

module PactBroker
  module Api
    module Resources
      class Clean < BaseResource
        def content_types_provided
          [["application/hal+json"]]
        end

        def allowed_methods
          ["POST", "OPTIONS"]
        end

        def process_post
          if content_type_json?
            keep_selectors = (params[:keep] || []).collect do | hash |
              PactBroker::DB::Clean::Selector.new(hash)
            end

            result = PactBroker::DB::Clean.call(Sequel::Model.db, { keep: keep_selectors })
            response.body = result.to_json
          else
            415
          end
        end

        def policy_name
          :'integrations::clean'
        end
      end
    end
  end
end
