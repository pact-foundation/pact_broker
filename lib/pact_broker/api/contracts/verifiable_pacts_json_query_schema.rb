require 'dry-validation'
require 'pact_broker/hash_refinements'
require 'pact_broker/string_refinements'
require 'pact_broker/api/contracts/dry_validation_workarounds'
require 'pact_broker/api/contracts/dry_validation_predicates'

module PactBroker
  module Api
    module Contracts
      class VerifiablePactsJSONQuerySchema
        extend DryValidationWorkarounds
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
              optional(:latest).filled(included_in?: [true, false])
              optional(:fallbackTag).filled(:str?)
              optional(:consumer).filled(:str?, :not_blank?)

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
            errors = []
            params[:consumerVersionSelectors].each_with_index do | selector, index |
              if selector[:fallbackTag] && !selector[:latest]
                errors << "fallbackTag can only be set if latest is true (at index #{index})"
              end


              if not_provided?(selector[:tag]) && selector[:latest] != true
                errors << "latest must be true, or a tag must be provided (at index #{index})"
              end
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
      end
    end
  end
end
