require "uri"
require "pact_broker/hash_refinements"

module PactBroker
  module Config
    module RuntimeConfigurationLoggingMethods
      using PactBroker::HashRefinements

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
        # base_url raises a not implemented error
        def log_configuration(logger)
          source_info = to_source_trace
          (self.class.config_attributes - [:base_url]).collect(&:to_s).each_with_object({})do | key, new_hash |
            new_hash[key] = {
              value: self.send(key.to_sym),
              source: source_info.dig(key, :source) || source_info.dig(key) || { type: :defaults }
            }
          end.sort_by { |key, _| key }.each { |key, value| log_config_inner(key, value, logger) }
          if self.webhook_redact_sensitive_data == false
            logger.warn("WARNING!!! webhook_redact_sensitive_data is set to false. This will allow authentication information to be included in the webhook logs. This should only be used for debugging purposes. Do not run the application permanently in production with this value.")
          end
        end

        def log_config_inner(key, value, logger)
          # TODO fix the source display for webhook_certificates set by environment variables
          if !value.has_key? :value
            value.sort_by { |inner_key, _| inner_key }.each { |inner_key, inner_value| log_config_inner("#{key}.#{inner_key}", inner_value, logger) }
          elsif self.class.sensitive_value?(key)
            logger.info "#{key}=#{redact(key, value[:value])} source=#{value[:source]}"
          else
            logger.info "#{key}=#{value[:value].inspect} source=#{value[:source]}"
          end
        end
        private :log_config_inner

        def redact name, value
          if value && name.to_s.end_with?("_url")
            begin
              uri = URI(value)
              if uri.password
                uri.password = "*****"
                uri.to_s
              else
                value
              end
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
