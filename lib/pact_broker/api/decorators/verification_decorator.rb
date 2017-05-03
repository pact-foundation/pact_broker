require_relative 'base_decorator'

module PactBroker
  module Api
    module Decorators
      class VerificationDecorator < BaseDecorator

        property :provider_name, as: :providerName, writeable: :false
        property :provider_version, as: :providerApplicationVersion
        property :success
        property :execution_date, as: :verificationDate
        property :build_url, as: :buildUrl

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

        def provider_name
          represented.provider_name
        end
      end
    end
  end
end
