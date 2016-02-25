require 'pact_broker/domain/group'

=begin
  Splits all relationships up into groups of non-connecting relationships.
=end

module PactBroker

  module Relationships

    class Groupify

      def self.call relationships
        recurse_groups([], relationships.dup).collect { |group| Domain::Group.new(group) }
      end

      def self.recurse_groups groups, relationship_pool
        if relationship_pool.empty?
          groups
        else
          first, *rest = relationship_pool
          group = [first]
          new_connections = true
          while new_connections
            new_connections = false
            group = rest.inject(group) do |connected, candidate|
              if connected.select { |relationship| relationship.connected?(candidate) }.any?
                new_connections = true
                connected + [candidate]
              else
                connected
              end
            end

            rest = rest - group
            group.uniq
          end

          recurse_groups(groups + [group], relationship_pool - group)
        end
      end
    end

  end
end
