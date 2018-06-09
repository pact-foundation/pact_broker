module PactBroker
  module Webhooks
    class Render
      def self.call(template, pact, verification = nil, &escaper)
        base_url = PactBroker.configuration.base_url
        params = {
          '${pactbroker.pactUrl}' => PactBroker::Api::PactBrokerUrls.pact_url(base_url, pact),
          '${pactbroker.consumerVersionNumber}' => pact.consumer_version_number,
          '${pactbroker.providerVersionNumber}' => verification ? verification.provider_version_number : "",
          '${pactbroker.consumerName}' => pact.consumer_name,
          '${pactbroker.providerName}' => pact.provider_name,
          '${pactbroker.githubVerificationStatus}' => github_verification_status(verification)
        }

        if escaper
          params.keys.each do | key |
            params[key] = escaper.call(params[key])
          end
        end

        params.inject(template) do | template, (key, value) |
          template.gsub(key, value)
        end
      end

      def self.github_verification_status verification
        if verification
          verification.success ? "success" : "failure"
        else
          ""
        end
      end
    end
  end
end
