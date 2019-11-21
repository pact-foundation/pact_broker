require 'dry-validation'

module PactBroker
  module Api
    module Contracts
      module DryValidationPredicates
        include Dry::Logic::Predicates

        predicate(:date?) do |value|
          DateTime.parse(value) rescue false
        end
      end
    end
  end
end
