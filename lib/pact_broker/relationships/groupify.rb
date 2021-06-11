require "pact_broker/domain/group"

=begin
  Splits all index_items up into groups of non-connecting index_items.
=end

module PactBroker

  module Relationships

    class Groupify

      def self.call index_items
        recurse_groups([], index_items.dup).collect { |group| Domain::Group.new(group) }
      end

      def self.recurse_groups groups, index_item_pool
        if index_item_pool.empty?
          groups
        else
          first, *rest = index_item_pool
          group = [first]
          new_connections = true
          while new_connections
            new_connections = false
            group = rest.inject(group) do |connected, candidate|
              if connected.select { |index_item| index_item.connected?(candidate) }.any?
                new_connections = true
                connected + [candidate]
              else
                connected
              end
            end

            rest = rest - group
            group.uniq
          end

          recurse_groups(groups + [group], index_item_pool - group)
        end
      end
    end

  end
end
