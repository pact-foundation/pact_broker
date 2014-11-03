require 'pact_broker/ui/view_models/relationship'

module PactBroker
  module UI
    module ViewDomain
      class Relationships

        def initialize relationships
          @relationships = relationships.collect{ |relationship| Relationship.new(relationship) }.sort
        end

        def each(&block)
          relationships.each(&block)
        end

        def size_label
          case relationships.size
          when 1 then "1 pact"
          else
            "#{relationships.size} pacts"
          end
        end

        private

        attr_reader :relationships
      end
    end
  end
end