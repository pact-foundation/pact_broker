module PactBroker
  module Config
    module RuntimeConfigurationLoggingMethods
      def log_configuration(logger)
        loggable_attributes.sort.each do | setting |
          logger.info "PactBroker.configuration.#{setting}=#{maybe_redact(setting.to_s, self.send(setting))}"
        end
      end

      def loggable_attributes
        self.class.attribute_names - [:database_configuration]
      end
      private :loggable_attributes

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
