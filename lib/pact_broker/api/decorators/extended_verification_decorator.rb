require "pact_broker/api/decorators/verification_decorator"

module PactBroker
  module Api
    module Decorators
      class ExtendedVerificationDecorator < VerificationDecorator
        class TagDecorator < BaseDecorator
          property :name
          property :latest?, as: :latest

          link :self do | options |
            {
              title: "Tag",
              name: represented.name,
              href: tag_url(options[:base_url], represented)
            }
          end
        end

        collection :provider_version_tags, as: :tags, embedded: true, extend: TagDecorator
      end
    end
  end
end
