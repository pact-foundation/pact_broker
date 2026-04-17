require "pact_broker/hash_refinements"

module PactBroker
  module DB
    class Clean
      class BranchSelector
        using PactBroker::HashRefinements

        ATTRIBUTES = [:max_age, :branch]

        attr_accessor(*ATTRIBUTES)

        def initialize(attributes = {})
          attributes.each do | (name, value) |
            instance_variable_set("@#{name}", value) if respond_to?(name)
          end
          @source_hash = attributes[:source_hash]
        end

        def self.from_hash(hash)
          standard_hash = hash.symbolize_keys.snakecase_keys
          new_hash = standard_hash.slice(*ATTRIBUTES)
          new_hash[:source_hash] = hash
          new(new_hash.compact)
        end

        def to_hash
          ATTRIBUTES.each_with_object({}) do | key, hash |
            hash[key] = send(key)
          end.compact
        end
        alias_method :to_h, :to_hash

        def to_json(_opts = nil)
          (@source_hash || to_hash).to_json
        end
      end
    end
  end
end
