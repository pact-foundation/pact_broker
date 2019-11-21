require_relative 'base_decorator'
require_relative 'verifiable_pact_decorator'
require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/hash_refinements'

module PactBroker
  module Api
    module Decorators
      class VerifiablePactsQueryDecorator < BaseDecorator
        using PactBroker::HashRefinements

        collection :provider_version_tags, default: []

        collection :consumer_version_selectors, default: [], class: OpenStruct do
          property :tag
          property :latest,
            setter: ->(fragment:, represented:, **) {
              represented.latest = (fragment == 'true' || fragment == true)
            }
        end

        property :include_pending_status, default: true,
          setter: ->(fragment:, represented:, **) {
            represented.include_pending_status = (fragment == 'true' || fragment == true)
          }

        def from_hash(hash)
          # This handles both the snakecase keys from the GET query and the camelcase JSON POST body
          super(hash&.snakecase_keys)
        end
      end
    end
  end
end
