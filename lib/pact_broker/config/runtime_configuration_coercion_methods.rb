require "pact_broker/config/space_delimited_string_list"
require "pact_broker/config/space_delimited_integer_list"

module PactBroker
  module Config
    module RuntimeConfigurationCoercionMethods

      def all_keys_are_number_strings?(hash)
        hash.keys.all? { | k | k.to_s.to_i.to_s == k } # is an integer as a string
      end

      def convert_hash_with_number_string_keys_to_array(hash)
        hash.keys.collect{ |k| [k, k.to_i]}.sort_by(&:last).collect(&:first).collect do | key |
          hash[key]
        end
      end

      def value_to_string_array value, property_name
        if value.is_a?(String)
          PactBroker::Config::SpaceDelimitedStringList.parse(value)
        elsif value.is_a?(Array)
          # parse structured values to possible regexp
          [*value].flat_map do | val |
            if val.is_a?(String)
              PactBroker::Config::SpaceDelimitedStringList.parse(val)
            else
              [val]
            end
          end
        elsif value
          raise ConfigurationError.new("Pact Broker configuration property `#{property_name}` must be a space delimited String or an Array. Got: #{value.inspect}")
        end
      end

      private :value_to_string_array

      def value_to_integer_array value, property_name
        if value.is_a?(String)
          PactBroker::Config::SpaceDelimitedIntegerList.parse(value)
        elsif value.is_a?(Array)
          value.collect { |v| v.to_i }
        elsif value.is_a?(Integer)
          [value]
        elsif value
          raise ConfigurationError.new("Pact Broker configuration property `#{property_name}` must be a space delimited String or an Array of Integers. Got: #{value.inspect}")
        end
      end

      private :value_to_integer_array
    end
  end
end
