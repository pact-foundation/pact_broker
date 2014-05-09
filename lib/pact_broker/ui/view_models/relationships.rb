require 'pact_broker/ui/view_models/relationship'

module PactBroker
  module UI
    module ViewModels
      class Relationships

        attr_reader :relationships

        def initialize relationships
          @relationships = relationships.collect{ |relationship| Relationship.new(relationship) }
        end

        def each(&block)
          relationships.each(&block)
        end

      end
    end
  end
end