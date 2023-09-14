require "pact_broker/config/space_delimited_string_list"
require "pact_broker/config/space_delimited_integer_list"
require "pact_broker/hash_refinements"
require "pact_broker/error"

module PactBroker
  module Config
    module RuntimeConfigurationCoercionMethods

      using PactBroker::HashRefinements

      COERCE_FEATURES = lambda { | value |
        if value.is_a?(String)
          value.split(" ").each_with_object({}) { | k, h | h[k.downcase.to_sym] = true }
        elsif value.is_a?(Array)
          value.each_with_object({}) { | k, h | h[k.downcase.to_sym] = true }
        elsif value.is_a?(Hash)
          value.each_with_object({}) { | (k, v), new_hash | new_hash[k.downcase.to_sym] = Anyway::AutoCast.call(v) }
        else
          raise PactBroker::ConfigurationError, "Expected a String, Hash or Array for features but got a #{value.class.name}"
        end
      }

      COERCE_WEBHOOKS = lambda { | value |
        if value.is_a?(Hash) # from env vars
          if RuntimeConfigurationCoercionMethods.all_keys_are_number_strings?(value)
            RuntimeConfigurationCoercionMethods.convert_hash_with_number_string_keys_to_array(value).collect(&:symbolize_keys)
          else
            raise PactBroker::ConfigurationError, "Could not coerce #{value} into an array of webhook configurations. Please check docs for the expected format."
          end
        elsif value.is_a?(Array) # from YAML
          value.collect(&:symbolize_keys)
        else
          raise PactBroker::ConfigurationError, "Webhook certificates cannot be set using a #{value.class}"
        end
      }

      def self.all_keys_are_number_strings?(hash)
        hash.keys.all? { | k | k.to_s.to_i.to_s == k } # is an integer as a string
      end

      def self.convert_hash_with_number_string_keys_to_array(hash)
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
