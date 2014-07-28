require 'pact_broker/repositories'
require 'set'

module PactBroker

  module Services
    module GroupService

      extend self

      extend PactBroker::Repositories

      def find_group_containing pacticipant_name

      end



      class Groupify

        def call relationships
          recurse_groups [], relationships.dup
        end

        def recurse_groups groups, relationship_pool
          if relationship_pool.empty?
            groups
          else
            first, *rest = *relationship_pool
            group = recurse first, rest
            recurse_groups(groups + [group], relationship_pool - group)
          end
        end

        def recurse relationship, relationship_pool
          connected_relationships = relationship_pool.select{ | candidate| candidate.include?(relationship) }
          if connected_relationships.empty?
            [relationship]
          else
            ([relationship] + connected_relationships.map{| connected_relationship| recurse(connected_relationship, relationship_pool - connected_relationships)}.flatten).uniq
          end
        end

      end

    end
  end
end