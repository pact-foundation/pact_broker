module PactBroker
  module Webhooks
    class Render
      def self.call(body, pact, verification = nil, &escaper)
        base_url = PactBroker.configuration.base_url
        params = {
          '${pactbroker.pactUrl}' => PactBroker::Api::PactBrokerUrls.pact_url(base_url, pact),
          '${pactbroker.consumerVersionNumber}' => pact.consumer_version_number,
          '${pactbroker.providerVersionNumber}' => verification ? verification.provider_version_number : ""
        }

        if escaper
          params.keys.each do | key |
            params[key] = escaper.call(params[key])
          end
        end

        params.inject(body) do | body, (key, value) |
          body.gsub(key, value)
        end
      end
    end
  end
end
