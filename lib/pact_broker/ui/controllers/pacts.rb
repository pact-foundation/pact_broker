require 'pact_broker/ui/controllers/base_controller'

module PactBroker
  module UI
    module Controllers
      class Pacts < Base
        include PactBroker::Services

        get "/provider/:provider_name/consumer/:consumer_name/pact-version/:pact_version/verification-results/:number" do
          url = URI.parse("#{env["pactbroker.base_url"]}/hal-browser/browser.html")
          url.fragment = "#{env["pactbroker.base_url"]}#{env["SCRIPT_NAME"]}#{env["PATH_INFO"]}"
          response.headers["Location"] = url.to_s
          response.status = 302
        end
      end
    end
  end
end
