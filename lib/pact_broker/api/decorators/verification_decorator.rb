require_relative 'base_decorator'

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

        link :self do | options |
          {
            title: 'Verification result',
            name: "Verification result #{represented.number} for #{represented.latest_pact_publication.name}",
            href: verification_url(represented, options.fetch(:base_url), )
          }
        end

        link 'pb:pact-version' do | options |
          {
            title: 'Pact',
            name: represented.latest_pact_publication.name,
            href: pact_url(options.fetch(:base_url), represented.latest_pact_publication)
          }
        end

        link 'pb:triggered-webhooks' do | options |
          {
            title: 'Webhooks triggered by the publication of this verification result',
            href: verification_triggered_webhooks_url(represented, options.fetch(:base_url))
          }
        end
      end
    end
  end
end
