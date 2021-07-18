module PactBroker
  module Config
    module RuntimeConfigurationLoggingMethods
      def log_configuration(logger)
        to_h.to_a.sort_by(&:first).each do | key, value |
          logger.info "PactBroker.configuration.#{key}=#{maybe_redact(key.to_s, value)}"
        end
      end

      def maybe_redact name, value
        if value && name == "database_url"
          begin
            uri = URI(value)
            uri.password = "*****"
            uri.to_s
          rescue StandardError
            "*****"
          end
        elsif value && (name.include?("password") || name.include?("key"))
          "*****"
        else
          value.inspect
        end
      end
      private :maybe_redact
    end
  end
end
