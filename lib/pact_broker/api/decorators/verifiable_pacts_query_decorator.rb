require_relative "base_decorator"
require_relative "verifiable_pact_decorator"
require "pact_broker/api/pact_broker_urls"
require "pact_broker/hash_refinements"
require "pact_broker/pacts/selector"
require "pact_broker/pacts/selectors"

module PactBroker
  module Api
    module Decorators
      class VerifiablePactsQueryDecorator < BaseDecorator
        using PactBroker::HashRefinements

        collection :provider_version_tags, default: []
        property :provider_version_branch

        collection :consumer_version_selectors, default: PactBroker::Pacts::Selectors.new, class: PactBroker::Pacts::Selector do
          property :tag
          property :branch, setter: -> (fragment:, represented:, **) {
            represented.branch = fragment
            represented.latest = true
          }
          property :latest,
            setter: ->(fragment:, represented:, **) {
              represented.latest = (fragment == "true" || fragment == true)
            }
          property :fallback_tag
          property :fallback_branch
          property :consumer
          property :environment, setter: -> (fragment:, represented:, **) {
            represented.environment = fragment
            represented.currently_deployed = true
          }
          property :currently_deployed
        end

        property :include_pending_status, default: false,
          setter: ->(fragment:, represented:, **) {
            represented.include_pending_status = (fragment == "true" || fragment == true)
          }

        property :include_wip_pacts_since, default: nil,
          setter: ->(fragment:, represented:, **) {
            represented.include_wip_pacts_since = fragment ? DateTime.parse(fragment) : nil
          }

        def from_hash(hash)
          # This handles both the snakecase keys from the GET query and the camelcase JSON POST body
          result = super(hash&.snakecase_keys)
          if result.consumer_version_selectors && !result.consumer_version_selectors.is_a?(PactBroker::Pacts::Selectors)
            result.consumer_version_selectors = PactBroker::Pacts::Selectors.new(result.consumer_version_selectors)
          end
          result
        end
      end
    end
  end
end
