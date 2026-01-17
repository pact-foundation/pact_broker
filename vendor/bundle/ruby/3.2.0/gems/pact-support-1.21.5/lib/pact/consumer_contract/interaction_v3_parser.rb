require 'pact/consumer_contract/request'
require 'pact/consumer_contract/response'
require 'pact/consumer_contract/provider_state'
require 'pact/symbolize_keys'
require 'pact/matching_rules'
require 'pact/errors'
require 'pact/consumer_contract/string_with_matching_rules'

module Pact
  class InteractionV3Parser

    include SymbolizeKeys

    def self.call hash, options
      request = parse_request(hash['request'], options)
      response = parse_response(hash['response'], options)
      provider_states = parse_provider_states(hash['providerStates'])
      provider_state = provider_states.any? ? provider_states.first.name : nil
      if provider_states && provider_states.size > 1
        Pact.configuration.error_stream.puts("WARN: Currently only 1 provider state is supported. Ignoring ")
      end
      metadata = parse_metadata(hash['metadata'])
      Interaction.new(symbolize_keys(hash).merge(request: request,
                                                 response: response,
                                                 provider_states: provider_states,
                                                 provider_state: provider_state,
                                                 metadata: metadata))
    end

    def self.parse_request request_hash, options
      request_matching_rules = request_hash['matchingRules'] || {}
      if request_hash['body'].is_a?(String)
        parse_request_with_string_body(request_hash, request_matching_rules['body'] || {}, options)
      else
        parse_request_with_non_string_body(request_hash, request_matching_rules, options)
      end
    end

    def self.parse_response response_hash, options
      response_matching_rules = response_hash['matchingRules'] || {}
      if response_hash['body'].is_a?(String)
        parse_response_with_string_body(response_hash, response_matching_rules['body'] || {}, options)
      else
        parse_response_with_non_string_body(response_hash, response_matching_rules, options)
      end
    end

    def self.parse_request_with_non_string_body request_hash, request_matching_rules, options
      request_hash = request_hash.keys.each_with_object({}) do | key, new_hash |
        new_hash[key] = Pact::MatchingRules.merge(request_hash[key], look_up_matching_rules(key, request_matching_rules), options)
      end
      Pact::Request::Expected.from_hash(request_hash)
    end

    def self.parse_response_with_non_string_body response_hash, response_matching_rules, options
      response_hash = response_hash.keys.each_with_object({}) do | key, new_hash |
        new_hash[key] = Pact::MatchingRules.merge(response_hash[key], look_up_matching_rules(key, response_matching_rules), options)
      end
      Pact::Response.from_hash(response_hash)
    end

    def self.parse_request_with_string_body request_hash, request_matching_rules, options
      string_with_matching_rules = StringWithMatchingRules.new(request_hash['body'], options[:pact_specification_version], request_matching_rules)
      Pact::Request::Expected.from_hash(request_hash.merge('body' => string_with_matching_rules))
    end

    def self.parse_response_with_string_body response_hash, response_matching_rules, options
      string_with_matching_rules = StringWithMatchingRules.new(response_hash['body'], options[:pact_specification_version], response_matching_rules)
      Pact::Response.from_hash(response_hash.merge('body' => string_with_matching_rules))
    end

    def self.parse_provider_states provider_states
      (provider_states || []).collect do | provider_state_hash |
        Pact::ProviderState.new(provider_state_hash['name'], provider_state_hash['params'])
      end
    end

    def self.parse_metadata metadata_hash
      symbolize_keys(metadata_hash)
    end

    def self.look_up_matching_rules(key, matching_rules)
      # The matching rules for the path operate on the object itself and don't have sub paths
      # Convert it into the format that Merge expects.
      if key == 'path'
        matching_rules[key] ? { '$.' => matching_rules[key] } : nil
      else
        matching_rules[key]
      end
    end
  end
end
