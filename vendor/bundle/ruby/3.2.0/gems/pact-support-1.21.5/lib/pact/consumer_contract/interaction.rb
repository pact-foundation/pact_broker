require 'pact/shared/active_support_support'
require 'pact/consumer_contract/interaction_parser'

module Pact
  class Interaction
    include ActiveSupportSupport

    attr_accessor :description, :request, :response, :provider_state, :provider_states, :metadata, :_id, :index

    def initialize attributes = {}
      @description = attributes[:description]
      @request = attributes[:request]
      @response = attributes[:response]
      @provider_state = attributes[:provider_state] || attributes[:providerState]
      @provider_states = attributes[:provider_states]
      @metadata = attributes[:metadata]
      @_id = attributes[:_id]
      @index = attributes[:index]
    end

    def self.from_hash hash, options = {}
      InteractionParser.call(hash, options)
    end

    def to_hash
      h = { description: description }

      if provider_states
        h[:provider_states] = provider_states.collect(&:to_hash)
      else
        h[:provider_state] = provider_state
      end

      h[:request] = request.to_hash
      h[:response] = response.to_hash
      h[:metadata] = metadata
      h
    end

    def http?
      true
    end

    def validate!
      raise Pact::InvalidInteractionError.new(self) unless description && request && response
    end

    def matches_criteria? criteria
      criteria.each do | key, value |
        unless match_criterion self.send(key.to_s), value
          return false
        end
      end
      true
    end

    def match_criterion target, criterion
      target == criterion || (criterion.is_a?(Regexp) && criterion.match(target))
    end

    def == other
      other.is_a?(Interaction) && to_hash == other.to_hash
    end

    def eq? other
      self == other
    end

    def description_with_provider_state_quoted
      provider_state ? "\"#{description}\" given \"#{provider_state}\"" : "\"#{description}\""
    end

    def request_modifies_resource_without_checking_response_body?
      request.modifies_resource? && response.body_allows_any_value?
    end

    def to_s
      to_hash.to_s
    end
  end
end
