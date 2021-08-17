require "pact_broker/hash_refinements"

module PactBroker
  module DB
    class Clean
      class Selector
        using PactBroker::HashRefinements

        ATTRIBUTES = [:pacticipant_name, :latest, :tag, :branch, :environment_name, :max_age, :deployed, :released, :main_branch]

        attr_accessor *ATTRIBUTES

        def initialize(attributes = {})
          attributes.each do | (name, value) |
            instance_variable_set("@#{name}", value) if respond_to?(name)
          end
          @source_hash = attributes[:source_hash]
        end

        def self.from_hash(hash)
          standard_hash = hash.symbolize_keys.snakecase_keys
          new_hash = standard_hash.slice(*ATTRIBUTES)
          new_hash[:pacticipant_name] ||= standard_hash[:pacticipant] if standard_hash[:pacticipant]
          new_hash[:environment_name] ||= standard_hash[:environment] if standard_hash[:environment]
          new_hash[:source_hash] = hash
          new(new_hash.compact)
        end

        def to_hash
          ATTRIBUTES.each_with_object({}) do | key, hash |
            hash[key] = send(key)
          end.compact
        end
        alias_method :to_h, :to_hash

        def to_json
          (@source_hash || to_hash).to_json
        end

        def currently_deployed?
          !!deployed
        end

        def currently_supported?
          !!released
        end

        def latest?
          !!latest
        end
      end
    end
  end
end
