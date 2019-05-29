require_relative 'base_decorator'
require 'pact_broker/api/pact_broker_urls'
require 'delegate'

module PactBroker
  module Api
    module Decorators
      class VerifiablePactDecorator < BaseDecorator

        class Reshaper < SimpleDelegator
          def verification_properties
            __getobj__()
          end
        end

        def initialize(verifiable_pact)
          super(Reshaper.new(verifiable_pact))
        end

        property :pending # remove?

        property :verification_properties, as: :verificationProperties do
          property :pending
          property :pending_reason, as: :pendingReason, exec_context: :decorator
          property :inclusion_reason, as: :inclusionReason, exec_context: :decorator

          def inclusion_reason
            if represented.consumer_tags.any?
              "This pact is being verified because it is the latest for tags #{represented.consumer_tags.join(", ")}"
            else
              "This pact is being verified because it is the latest."
            end
          end

          def pending_reason
            tag_desc = if represented.pending_provider_tags.size == 1
              "tag #{represented.pending_provider_tags.first}"
            else
              "all of tags #{represented.pending_provider_tags}"
            end

            if represented.pending
              version_desc = if represented.pending_provider_tags.size == 1
               "any version"
              else
                "all versions"
              end

              "This pact is pending because it has not yet been verified successfully by #{version_desc} of #{represented.provider_name} with #{tag_desc}. If verification fails, it will not fail the build."
            else
              "This pact is not pending as it has previously been successfully verifed by a version of #{represented.provider_name} with #{tag_desc}. If verification fails, it will fail the build."
            end
          end

        end

        link :self do | context |
          {
            href: pact_version_url(represented, context[:base_url]),
            name: represented.name
          }
        end
      end
    end
  end
end
