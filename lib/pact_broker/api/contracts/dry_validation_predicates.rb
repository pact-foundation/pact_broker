require 'dry-validation'

module PactBroker
  module Api
    module Contracts
      module DryValidationPredicates
        include Dry::Logic::Predicates

        predicate(:date?) do |value|
          DateTime.parse(value) rescue false
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
      end
    end
  end
end
