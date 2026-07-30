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

      # log_appenders arrives either as an array (from YAML) or as a hash with
      # numeric string keys (from PACT_BROKER_LOG_APPENDERS__0__STREAM style
      # environment variables), exactly like webhook_certificates.
      #
      # Keys become symbols. The values of the keys we own are coerced; every
      # other value is left alone, because it is passed through to the appender.
      COERCE_LOG_APPENDERS = lambda { | value |
        entries =
          if value.nil?
            nil
          elsif value.is_a?(Array)
            value
          elsif value.is_a?(Hash)
            if RuntimeConfigurationCoercionMethods.all_keys_are_number_strings?(value)
              RuntimeConfigurationCoercionMethods.convert_hash_with_number_string_keys_to_array(value)
            else
              raise PactBroker::ConfigurationError,
                "Could not coerce #{value} into a list of log_appenders. Please check the docs for the expected format."
            end
          else
            raise PactBroker::ConfigurationError, "log_appenders cannot be set using a #{value.class}"
          end

        entries&.collect { | entry | RuntimeConfigurationCoercionMethods.coerce_log_appender_entry(entry) }
      }

      def self.coerce_log_appender_entry(entry)
        raise PactBroker::ConfigurationError, "Each log_appenders entry must be a map, got a #{entry.class}" unless entry.is_a?(Hash)

        entry.each_with_object({}) do | (key, value), new_entry |
          new_key = key.to_sym
          new_entry[new_key] =
            case new_key
            when :stream, :format, :appender then value&.to_sym
            when :enabled then coerce_log_appender_enabled(value)
            else value
            end
        end
      end

      def self.coerce_log_appender_enabled(value)
        case value
        when nil, "", "auto", :auto then :auto
        when true, "true", "1", 1 then true
        when false, "false", "0", 0 then false
        else value
        end
      end

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
