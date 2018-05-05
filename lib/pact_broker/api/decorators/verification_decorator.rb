require_relative 'base_decorator'

module PactBroker
  module Api
    module Decorators
      class VerificationDecorator < BaseDecorator

        property :provider_name, as: :providerName, writeable: :false
        property :provider_version_number, as: :providerApplicationVersion, writeable: false
        property :success
        property :execution_date, as: :verificationDate
        property :build_url, as: :buildUrl
        property :test_results, as: :testResults

        link :self do | options |
          {
            title: 'Verification result',
            name: "Verification result #{represented.number} for #{represented.pact_version.name}",
            href: verification_url(represented, options.fetch(:base_url), )
          }
        end

        link 'pb:pact-version' do | options |
          {
            title: 'Pact',
            name: represented.pact_version.name,
            href: pact_version_url(represented.pact_version, options.fetch(:base_url))
          }
        end
      end
    end
  end
end
