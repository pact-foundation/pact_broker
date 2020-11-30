module PactBroker
  module Api
    module Resources
      module PactResourceMethods
        def set_post_deletion_response
          latest_pact = pact_service.find_latest_pact(
            consumer_name: pact_params[:consumer_name],
            provider_name: pact_params[:provider_name]
          )
          response_body = { "_links" => { index: { href: base_url } } }
          if latest_pact
            response_body["_links"]["pb:latest-pact-version"] = {
              href: latest_pact_url(base_url, latest_pact),
              title: "Latest pact"
            }
          end
          response.body = response_body.to_json
          response.headers["Content-Type" => "application/hal+json;charset=utf-8"]
        end
      end
    end
  end
end