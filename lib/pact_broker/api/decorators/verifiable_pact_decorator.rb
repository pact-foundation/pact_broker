require_relative 'base_decorator'
require 'pact_broker/api/pact_broker_urls'
require 'delegate'
require 'pact_broker/pacts/verifiable_pact_messages'

module PactBroker
  module Api
    module Decorators
      class VerifiablePactDecorator < BaseDecorator

        # Allows a "flat" VerifiablePact to look like it has
        # a nested verification_properties object for Reform
        class Reshaper < SimpleDelegator
          def verification_properties
            __getobj__()
          end
        end

        def initialize(verifiable_pact)
          super(Reshaper.new(verifiable_pact))
        end

        property :verification_properties, as: :verificationProperties do
          include PactBroker::Api::PactBrokerUrls

          property :pending,
            if: ->(context) { context[:options][:user_options][:include_pending_status] }
          property :wip, if: -> (context) { context[:represented].wip }

          property :notices, getter: -> (context) { context[:decorator].notices(context[:options][:user_options]) }
          property :noteToDevelopers, getter: -> (_) { "Please print out the text from the 'notices' rather than using the inclusionReason and the pendingReason fields. These will be removed when this API moves out of beta."}

          def notices(user_options)
            # TODO move this out of the decorator
            pact_url = pact_version_url(represented, user_options[:base_url])
            messages = PactBroker::Pacts::VerifiablePactMessages.new(represented, pact_url)

            the_notices = [{
              when: 'before_verification',
              text: messages.inclusion_reason
            }]

            if user_options[:include_pending_status]
              append_notice(the_notices, 'before_verification', messages.pending_reason)
              append_notice(the_notices, 'after_verification:success_true_published_false', messages.verification_success_true_published_false)
              append_notice(the_notices, 'after_verification:success_false_published_false', messages.verification_success_false_published_false)
              append_notice(the_notices, 'after_verification:success_true_published_true', messages.verification_success_true_published_true)
              append_notice(the_notices, 'after_verification:success_false_published_true', messages.verification_success_false_published_true)
            end
            the_notices
          end

          def append_notice the_notices, the_when, text
            if text
              the_notices << {
                when: the_when,
                text: text
              }
            end
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
