module PactBroker
  module Config
    module RuntimeConfigurationCoercionMethods
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
        else
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
        else
          raise ConfigurationError.new("Pact Broker configuration property `#{property_name}` must be a space delimited String or an Array of Integers. Got: #{value.inspect}")
        end
      end

      private :value_to_integer_array
    end
  end
end
