require_relative "base_decorator"
require "pact_broker/api/pact_broker_urls"
require "pact_broker/pacts/build_verifiable_pact_notices"
require "pact_broker/pacts/metadata"

module PactBroker
  module Api
    module Decorators
      class VerifiablePactDecorator < BaseDecorator
        include PactBroker::Pacts::Metadata

        property :shortDescription, getter: lambda { | represented:, ** | PactBroker::Pacts::VerifiablePactMessages.new(represented, nil).pact_version_short_description }

        nested :verificationProperties do
          include PactBroker::Api::PactBrokerUrls

          property :pending,
            if: ->(options:, **_other) { options.dig(:user_options, :include_pending_status) }
          property :wip,
            if: -> (represented:, **_other) { represented.wip }
          property :notices,
            getter: -> (decorator:, options:, **) { decorator.notices(options[:user_options]) }

          def notices(user_options)
            metadata = represented.wip ? { wip: true } : nil
            pact_url = pact_version_url_with_metadata(represented, metadata, user_options[:base_url])
            PactBroker::Pacts::BuildVerifiablePactNotices.call(represented, pact_url, user_options)
          end
        end

        link :self do | user_options |
          metadata = build_metadata_for_pact_for_verification(represented)
          {
            href: pact_version_url_with_metadata(represented, metadata, user_options[:base_url]),
            name: represented.name
          }
        end
      end
    end
  end
end
