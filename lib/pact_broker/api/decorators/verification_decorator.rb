require_relative "base_decorator"

module PactBroker
  module Api
    module Decorators
      class VerificationDecorator < BaseDecorator
        class TagDecorator < BaseDecorator
          property :name
          property :latest?, as: :latest
        end

        property :provider_name, as: :providerName, writeable: false
        property :provider_version_number, as: :providerApplicationVersion, writeable: false
        property :success
        property :execution_date, as: :verificationDate
        property :build_url, as: :buildUrl
        property :test_results, as: :testResults
        nested :verifiedBy do
          property :verified_by_implementation, as: :implementation
          property :verified_by_version, as: :version
        end

        link :self do | options |
          pact = options[:pact] || represented.latest_pact_publication
          {
            title: "Verification result",
            name: "Verification result #{represented.number} for #{pact.name}",
            href: verification_url(represented, options.fetch(:base_url), )
          }
        end

        link "pb:pact-version" do | options |
          pact = options[:pact] || represented.latest_pact_publication
          {
            title: "Pact",
            name: pact.name,
            href: pact_version_with_consumer_version_metadata_url(pact, options.fetch(:base_url))
          }
        end

        link "pb:triggered-webhooks" do | options |
          {
            title: "Webhooks triggered by the publication of this verification result",
            href: verification_triggered_webhooks_url(represented, options.fetch(:base_url))
          }
        end
      end
    end
  end
end
