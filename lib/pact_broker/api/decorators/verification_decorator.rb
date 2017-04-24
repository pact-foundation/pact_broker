require_relative 'base_decorator'

module PactBroker
  module Api
    module Decorators
      class VerificationDecorator < BaseDecorator

        property :success
        property :provider_version, as: :providerVersion
        property :build_url, as: :buildUrl

        link :self do | options |
          {
            title: 'Verification',
            name: represented.number,
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
      end
    end
  end
end
