require 'pact/matching_rules'
require 'pact/term'

module Pact
  class ResponseDecorator

    def initialize response, decorator_options = {}
      @response = response
      @decorator_options = decorator_options
    end

    def to_json(options = {})
      as_json.to_json(options)
    end

    def as_json options = {}
      include_matching_rules? ? with_matching_rules(attributes_hash) : attributes_hash
    end

    private

    attr_reader :response

    def attributes_hash
      hash = {}
      hash[:status]  = response.status  if response.specified?(:status)
      hash[:headers] = response.headers if response.specified?(:headers)
      hash[:body]    = response.body    if response.specified?(:body)
      hash
    end

    def include_matching_rules?
      pact_specification_version && !pact_specification_version.start_with?('1')
    end

    def with_matching_rules hash
      matching_rules = Pact::MatchingRules.extract hash
      example = Pact::Reification.from_term hash
      return example if matching_rules.empty?
      example.merge(matchingRules: matching_rules)
    end

    def pact_specification_version
      @decorator_options[:pact_specification_version]
    end
  end
end
