module PactBroker
  module Api
    module Contracts
      module DryValidationWorkarounds
        extend self

        # Takes the errors hash in the format it comes from dry-validation,
        # and smushes it into the format that the Pact Broker API expects.
        # Can't wait to get rid of this and just use a problem+json response format.
        def flatten_messages(messages)
          flatten_nested_messages(flatten_indexed_messages(messages))
        end

        # Transforms error messages like this:
        # { things: { 0 => ["an error"], 2 => ["another error"] } }
        # into this:
        # { things: ["an error (at index 0)", "another error (at index 2)" ] }
        #
        # @param [Hash] messages
        # @return [Hash]
        # @private
        def flatten_indexed_messages(messages)
          if messages.values.any?{ | value | is_indexed_structure?(value) }
            messages.each_with_object({}) do | (key, value), new_messages |
              new_messages[key] = is_indexed_structure?(value) ? flatten_array_of_hashes(value) : value
            end
          else
            messages
          end
        end

        # Transforms error messages like this:
        # { parent: { child: ["an error"] }
        # into this:
        # { :"parent.child" : ["an error"] }
        # because that was the way Reform did it, and now we need to keep it consistent.
        #
        # @param [Hash] messages
        # @return [Hash]
        # @private
        def flatten_nested_messages(hash, new_hash = {}, parent_keys = [])
          hash.each do | key, value |
            case value
            when Hash
              flatten_nested_messages(value, new_hash, parent_keys + [key])
            when Array
              new_hash[ (parent_keys + [key]).join(".").to_sym ] = value
            end
          end
          new_hash
        end


        # @private
        def is_indexed_structure?(thing)
          thing.is_a?(Hash) && thing.keys.all?{ | k | k.is_a?(Integer) }
        end

        # @private
        def flatten_array_of_hashes(array_of_hashes)
          array_of_hashes.collect do | index, hash_or_array |
            array = hash_or_array.is_a?(Hash) ?  collect_and_prepend_with_key(hash_or_array).flatten : hash_or_array
            array.collect { | text | "#{text} (at index #{index})"}
          end.flatten
        end

        # @private
        def collect_and_prepend_with_key(hash)
          hash.collect do | key, value |
            if value.is_a?(Hash)
              flatten_and_prepend_with_key(value)
            elsif value.is_a?(Array)
              value.collect{ | text | "#{key} #{text}"}
            else
              raise "Unexpected object"
            end
          end
        end
      end
    end
  end
end
