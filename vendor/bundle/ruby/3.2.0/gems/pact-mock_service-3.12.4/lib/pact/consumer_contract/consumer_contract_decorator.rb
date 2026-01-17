require 'pact/shared/active_support_support'
require 'pact/consumer_contract/interaction_decorator'

module Pact
  class ConsumerContractDecorator

    include ActiveSupportSupport

    def initialize consumer_contract, decorator_options = {}
      @consumer_contract = consumer_contract
      @decorator_options = decorator_options
    end

    def as_json(options = {})
      fix_all_the_things(
        consumer: consumer_contract.consumer.as_json,
        provider: consumer_contract.provider.as_json,
        interactions: sorted_interactions.collect{ |i| InteractionDecorator.new(i, @decorator_options).as_json},
        metadata: {
          pactSpecification: {
            version: pact_specification_version
          }
        }
      )
    end

    def to_json(options = {})
      as_json.to_json(options)
    end

    private

    def sorted_interactions
      # Default order: chronological
      return consumer_contract.writable_interactions if Pact.configuration.pactfile_write_order == :chronological
      # We are supporting only chronological or alphabetical order
      raise NotImplementedError if Pact.configuration.pactfile_write_order != :alphabetical

      consumer_contract.writable_interactions.sort{|a, b| sortable_id(a) <=> sortable_id(b)}
    end

    def sortable_id interaction
      "#{interaction.description.downcase} #{interaction.response.status} #{(interaction.provider_state || '').downcase}"
    end

    attr_reader :consumer_contract

    def pact_specification_version
      version = @decorator_options.fetch(:pact_specification_version)
      "#{version[0]}.0.0" # Only care about the first digit
    end
  end
end
