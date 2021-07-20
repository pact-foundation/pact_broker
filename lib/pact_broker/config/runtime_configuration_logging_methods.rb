require "uri"

module PactBroker
  module Config
    module RuntimeConfigurationLoggingMethods
      module ClassMethods
        def sensitive_values(*values)
          @sensitive_values ||= []
          if values
            @sensitive_values.concat([*values])
          else
            @sensitive_values
          end
        end

        def sensitive_value?(value)
          sensitive_values.any? { |key| key == value || key == value.to_sym || key.kind_of?(Regexp) && key =~ value }
        end
      end

      module InstanceMethods
        def log_configuration(logger)
          logger.info "------------------------------------------------------------------------"
          logger.info "PACT BROKER CONFIGURATION:"
          to_source_trace.sort_by { |key, _| key }.each { |key, value| log_config_inner(key, value, logger) }
          logger.info "------------------------------------------------------------------------"
        end

        def log_config_inner(key, value, logger)
          if !value.has_key? :value
            value.sort_by { |inner_key, _| inner_key }.each { |inner_key, inner_value| log_config_inner("#{key}:#{inner_key}", inner_value) }
          elsif self.class.sensitive_value?(key)
            logger.info "#{key}=#{redact(key, value[:value])} source=[#{value[:source]}]"
          else
            logger.info "#{key}=#{value[:value]} source=[#{value[:source]}]"
          end
        end
        private :log_config_inner

        def redact name, value
          if value && name.to_s.end_with?("_url")
            begin
              uri = URI(value)
              uri.password = "*****"
              uri.to_s
            rescue StandardError
              "*****"
            end
          elsif !value.nil?
            "*****"
          else
            nil
          end
        end
        private :redact
      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end
    end
  end
end
