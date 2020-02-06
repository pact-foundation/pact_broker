require_relative 'base_decorator'
require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/pacts/build_verifiable_pact_notices'

module PactBroker
  module Api
    module Decorators
      class VerifiablePactDecorator < BaseDecorator

        property :shortDescription, getter: -> (context) { PactBroker::Pacts::VerifiablePactMessages.new(context[:represented], nil).pact_version_short_description }

        nested :verificationProperties do
          include PactBroker::Api::PactBrokerUrls

          property :pending,
            if: ->(context) { context[:options][:user_options][:include_pending_status] }
          property :wip, if: -> (context) { context[:represented].wip }

          property :notices, getter: -> (context) { context[:decorator].notices(context[:options][:user_options]) }
          property :noteToDevelopers, getter: -> (_) { "Please print out the text from the 'notices' rather than using the inclusionReason and the pendingReason fields. These will be removed when this API moves out of beta."}

          def notices(user_options)
            pact_url = pact_version_url(represented, user_options[:base_url])
            PactBroker::Pacts::BuildVerifiablePactNotices.call(represented, pact_url, include_pending_status: user_options[:include_pending_status])
          end
        end

        link :self do | user_options |
          {
            href: pact_version_url(represented, user_options[:base_url]),
            name: represented.name
          }
        end
      end
    end
  end
end
