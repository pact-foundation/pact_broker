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
          property :verified_by_client_implementation, as: :client_implementation
          property :verified_by_client_test_framework, as: :client_test_framework
          property :verified_by_client_version, as: :client_version
        end

        link :self do | options |
          pact = pact_for(options)
          {
            title: "Verification result",
            name: "Verification result #{represented.number} for #{pact.name}",
            href: verification_url(represented, options.fetch(:base_url), )
          }
        end

        link "pb:pact-version" do | options |
          pact = pact_for(options)
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

        private

        # A decorator rendering many verifications passes :pacts_by_pact_version_sha
        # so each one avoids its own lookup.
        def pact_for(options)
          options[:pact] ||
            options[:pacts_by_pact_version_sha]&.[](represented.pact_version_sha) ||
            represented.latest_pact_publication
        end
      end
    end
  end
end
