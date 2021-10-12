require_relative "base_decorator"
require_relative "verifiable_pact_decorator"
require "pact_broker/api/pact_broker_urls"
require "pact_broker/hash_refinements"
require "pact_broker/pacts/selector"
require "pact_broker/pacts/selectors"

module PactBroker
  module Api
    module Decorators
      class PactsForVerificationQueryDecorator < BaseDecorator
        using PactBroker::HashRefinements

        collection :provider_version_tags, default: []
        property :provider_version_branch

        collection :consumer_version_selectors, default: PactBroker::Pacts::Selectors.new, class: PactBroker::Pacts::Selector do
          property :main_branch
          property :tag
          property :branch, setter: -> (fragment:, represented:, **) {
            represented.branch = fragment
            represented.latest = true
          }
          property :matching_branch, setter: -> (fragment:, represented:, **other) {
            represented.matching_branch = fragment
            represented.latest = true
          }
          property :latest,
            setter: ->(fragment:, represented:, **) {
              represented.latest = (fragment == "true" || fragment == true)
            }
          property :fallback_tag
          property :fallback_branch
          property :consumer
          property :environment_name, as: :environment
          property :currently_deployed, as: :deployed
          property :currently_supported, as: :released
          property :deployed_or_released,
            setter: ->(represented:, **) {
              represented.currently_deployed = true
              represented.currently_supported = true
            }
        end

        property :include_pending_status, default: true,
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

          result.consumer_version_selectors = split_out_deployed_or_released_selectors(result.consumer_version_selectors)
          if result.provider_version_branch
            result.consumer_version_selectors = set_branch_for_matching_branch_selectors(result.consumer_version_selectors, result.provider_version_branch)
          end

          if result.consumer_version_selectors && !result.consumer_version_selectors.is_a?(PactBroker::Pacts::Selectors)
            result.consumer_version_selectors = PactBroker::Pacts::Selectors.new(result.consumer_version_selectors)
          end
          result
        end

        private

        def set_branch_for_matching_branch_selectors(consumer_version_selectors, provider_version_branch)
          consumer_version_selectors.collect do | consumer_version_selector |
            if consumer_version_selector[:matching_branch]
              consumer_version_selector[:branch] = provider_version_branch
              consumer_version_selector
            else
              consumer_version_selector
            end
          end
        end

        def split_out_deployed_or_released_selectors(consumer_version_selectors)
          consumer_version_selectors.flat_map do | selector |
            if selector.currently_deployed && selector.currently_supported
              [
                PactBroker::Pacts::Selector.new(selector.to_hash.without(:currently_supported)),
                PactBroker::Pacts::Selector.new(selector.to_hash.without(:currently_deployed))
              ]
            else
              [selector]
            end
          end
        end
      end
    end
  end
end
