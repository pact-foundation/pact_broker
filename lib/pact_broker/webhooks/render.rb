module PactBroker
  module Webhooks
    class Render

      TEMPLATE_PARAMETER_REGEXP = /\$\{pactbroker\.[^\}]+\}/

      def self.call(template, pact, verification = nil, &escaper)
        base_url = PactBroker.configuration.base_url
        params = {
          '${pactbroker.pactUrl}' => pact ? PactBroker::Api::PactBrokerUrls.pact_url(base_url, pact) : "",
          '${pactbroker.verificationResultUrl}' => verification_url(pact, verification),
          '${pactbroker.consumerVersionNumber}' => pact ? pact.consumer_version_number : "",
          '${pactbroker.providerVersionNumber}' => verification ? verification.provider_version_number : "",
          '${pactbroker.consumerName}' => pact ? pact.consumer_name : "",
          '${pactbroker.providerName}' => pact ? pact.provider_name : "",
          '${pactbroker.githubVerificationStatus}' => github_verification_status(pact, verification)
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

      def self.github_verification_status pact, verification
        if verification
          verification.success ? "success" : "failure"
        elsif pact && pact.latest_verification
          pact.latest_verification.success ? "success" : "failure"
        elsif pact
          "pending"
        else
          ""
        end
      end

      def self.verification_url pact, verification
        if verification || (pact && pact.latest_verification)
          PactBroker::Api::PactBrokerUrls.verification_url(verification || pact.latest_verification, PactBroker.configuration.base_url)
        else
          ""
        end
      end
    end
  end
end
