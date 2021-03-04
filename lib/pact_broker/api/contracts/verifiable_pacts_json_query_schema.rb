require 'dry-validation'
require 'pact_broker/hash_refinements'
require 'pact_broker/string_refinements'
require 'pact_broker/api/contracts/dry_validation_workarounds'
require 'pact_broker/api/contracts/dry_validation_predicates'
require 'pact_broker/messages'

module PactBroker
  module Api
    module Contracts
      class VerifiablePactsJSONQuerySchema
        extend DryValidationWorkarounds
        extend PactBroker::Messages

        using PactBroker::HashRefinements
        using PactBroker::StringRefinements

        SCHEMA = Dry::Validation.Schema do
          configure do
            predicates(DryValidationPredicates)
            config.messages_file = File.expand_path("../../../locale/en.yml", __FILE__)
          end
          optional(:providerVersionTags).maybe(:array?)
          optional(:consumerVersionSelectors).each do
            schema do
              # configure do
              #   def self.messages
              #     super.merge(en: { errors: { fallbackTagMustBeForLatest: 'can only be set if latest=true' }})
              #   end
              # end

              optional(:tag).filled(:str?)
              optional(:branch).filled(:str?)
              optional(:latest).filled(included_in?: [true, false])
              optional(:fallbackTag).filled(:str?)
              optional(:fallbackBranch).filled(:str?)
              optional(:consumer).filled(:str?, :not_blank?)
              optional(:currentlyDeployed).filled(included_in?: [true])
              optional(:environment).filled(:str?)

              # rule(fallbackTagMustBeForLatest: [:fallbackTag, :latest]) do | fallback_tag, latest |
              #   fallback_tag.filled?.then(latest.eql?(true))
              # end
            end
          end
          optional(:includePendingStatus).filled(included_in?: [true, false])
          optional(:includeWipPactsSince).filled(:date?)
        end

        def self.call(params)
          symbolized_params = params&.symbolize_keys
          results = select_first_message(flatten_indexed_messages(SCHEMA.call(symbolized_params).messages(full: true)))
          add_cross_field_validation_errors(symbolized_params, results)
          results
        end

        def self.add_cross_field_validation_errors(params, results)
          # This is a ducking joke. Need to get rid of dry-validation
          if params[:consumerVersionSelectors].is_a?(Array)
            errors = params[:consumerVersionSelectors].each_with_index.flat_map do | selector, index |
              validate_consumer_version_selector(selector, index)
            end
            if errors.any?
              results[:consumerVersionSelectors] ||= []
              results[:consumerVersionSelectors].concat(errors)
            end
          end
        end

        def self.not_provided?(value)
          value.nil? || value.blank?
        end

        # when setting a tag, latest=true and latest=false are both valid
        # when setting the branch, it doesn't make sense to verify all pacts for a branch,
        # so latest is not required, but cannot be set to false
        def self.validate_consumer_version_selector(selector, index)
          errors = []

          if selector[:fallbackTag] && !selector[:latest]
            errors << "fallbackTag can only be set if latest is true (at index #{index})"
          end

          if selector[:fallbackBranch] && selector[:latest] == false
            errors << "fallbackBranch can only be set if latest is true (at index #{index})"
          end

          if not_provided?(selector[:tag]) &&
              not_provided?(selector[:branch]) &&
              not_provided?(selector[:environment]) &&
              selector[:currentlyDeployed] != true &&
              selector[:latest] != true
            errors << "must specify a value for environment or tag, or specify latest=true, or specify currentlyDeployed=true (at index #{index})"
          end

          if selector[:tag] && selector[:branch]
            errors << "cannot specify both a tag and a branch (at index #{index})"
          end

          if selector[:fallbackBranch] && !selector[:branch]
            errors << "a branch must be specified when a fallbackBranch is specified (at index #{index})"
          end

          if selector[:fallbackTag] && !selector[:tag]
            errors << "a tag must be specified when a fallbackTag is specified (at index #{index})"
          end

          if selector[:branch] && selector[:latest] == false
            errors << "cannot specify a branch with latest=false (at index #{index})"
          end

          non_environment_fields = selector.slice(:latest, :tag, :fallbackTag, :branch, :fallbackBranch).keys
          environment_related_fields = selector.slice(:environment, :currentlyDeployed).keys

          if (non_environment_fields.any? && environment_related_fields.any?)
            errors << "cannot specify the #{pluralize("field", non_environment_fields.count)} #{non_environment_fields.join("/")} with the #{pluralize("field", environment_related_fields.count)} #{environment_related_fields.join("/")} (at index #{index})"
          end

          errors
        end
      end
    end
  end
end
