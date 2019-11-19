module PactBroker
  module Api
    module Contracts
      module DryValidationWorkarounds
        extend self

        # I just cannot seem to get the validation to stop on the first error.
        # If one rule fails, they all come back failed, and it's driving me nuts.
        # Why on earth would I want that behaviour?
        def select_first_message(messages)
          messages.each_with_object({}) do | (key, value), new_messages |
            new_messages[key] = [value.first]
          end
        end

        def flatten_array_of_hashes(array_of_hashes)
          new_messages = array_of_hashes.collect do | index, hash |
            hash.values.flatten.collect { | text | "#{text} at index #{index}"}
          end.flatten
        end

        def flatten_indexed_messages(messages)
          if messages.values.any?{ | value | is_indexed_structure?(value) }
            messages.each_with_object({}) do | (key, value), new_messages |
              new_messages[key] = is_indexed_structure?(value) ? flatten_array_of_hashes(value) : value
            end
          else
            messages
          end
        end

        def is_indexed_structure?(thing)
          thing.is_a?(Hash) && thing.keys.first.is_a?(Integer)
        end
      end
    end
  end
end
