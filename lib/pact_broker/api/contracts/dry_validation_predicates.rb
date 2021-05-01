require 'dry-validation'

module PactBroker
  module Api
    module Contracts
      module DryValidationPredicates
        include Dry::Logic::Predicates

        predicate(:date?) do |value|
          DateTime.parse(value) rescue false
        end

        predicate(:base64?) do |value|
          Base64.strict_decode64(value) rescue false
        end

        predicate(:not_blank?) do | value |
          value && value.is_a?(String) && value.strip.size > 0
        end

        predicate(:single_line?) do | value |
          value && value.is_a?(String) && !value.include?("\n")
        end

        predicate(:no_spaces?) do | value |
          value && value.is_a?(String) && !value.include?(" ")
        end

        predicate(:environment_with_name_exists?) do | value |
          require 'pact_broker/deployments/environment_service'
          !!PactBroker::Deployments::EnvironmentService.find_by_name(value)
        end
      end
    end
  end
end
