require 'pact_broker/api/decorators/verification_decorator'

module PactBroker
  module Api
    module Decorators
      class ExtendedVerificationDecorator < VerificationDecorator
        class TagDecorator < BaseDecorator
          property :name
          property :latest?, as: :latest
        end

        collection :provider_version_tags, as: :tags, embedded: true, extend: TagDecorator
      end
    end
  end
end
