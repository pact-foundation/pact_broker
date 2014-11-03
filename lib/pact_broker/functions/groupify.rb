require 'pact_broker/domain/group'

=begin
  Splits all relationships up into groups of non-connecting relationships.
=end

module PactBroker

  module Functions

    class Groupify

      def self.call relationships
        recurse_groups([], relationships.dup).collect{ | group | Domain::Group.new(group) }
      end

      def self.recurse_groups groups, relationship_pool
        if relationship_pool.empty?
          groups
        else
          first, *rest = *relationship_pool
          group = recurse first, rest
          recurse_groups(groups + [group], relationship_pool - group)
        end
      end

      def self.recurse relationship, relationship_pool
        connected_relationships = relationship_pool.select{ | candidate| candidate.connected?(relationship) }
        if connected_relationships.empty?
          [relationship]
        else
          ([relationship] + connected_relationships.map{| connected_relationship| recurse(connected_relationship, relationship_pool - connected_relationships)}.flatten).uniq
        end
      end

    end

  end
end