require "anyway_config"

module PactBroker
  module Config
    class RuntimeConfiguration < Anyway::Config
      DATABASE_ATTRIBUTES = {
        auto_migrate_db: true,
        auto_migrate_db_data: true,
        allow_missing_migration_files: false,
        validate_database_connection_config: true,
        use_case_sensitive_resource_names: true,
        metrics_sql_statement_timeout: 30,
      }

      LOGGING_ATTRIBUTES = {
        log_dir: File.expand_path("./log"),
        warning_error_class_names: ["Sequel::ForeignKeyConstraintViolation", "PG::QueryCanceled"],
      }

      WEBHOOK_ATTRIBUTES = {
        webhook_retry_schedule: [10, 60, 120, 300, 600, 1200], #10 sec, 1 min, 2 min, 5 min, 10 min, 20 min => 38 minutes
        webhook_http_method_whitelist: ["POST"],
        webhook_http_code_success: [200, 201, 202, 203, 204, 205, 206],
        webhook_scheme_whitelist: ["https"],
        webhook_host_whitelist: [],
        disable_ssl_verification: false,
        user_agent: "Pact Broker v#{PactBroker::VERSION}",
      }

      RESOURCE_ATTRIBUTES = {
        base_url: nil,
        use_hal_browser: true,
        enable_diagnostic_endpoints: true,
        use_rack_protection: true,
        badge_provider_mode: :proxy,
        enable_public_badge_access: false,
        shields_io_base_url: "https://img.shields.io",
      }

      DOMAIN_ATTRIBUTES = {
        order_versions_by_date: true,
        base_equality_only_on_content_that_affects_verification_results: true,
        check_for_potential_duplicate_pacticipant_names: true,
        create_deployed_versions_for_tags: true,
        semver_formats: ["%M.%m.%p%s%d", "%M.%m", "%M"]
      }

      ALL_ATTRIBUTES = [DATABASE_ATTRIBUTES, LOGGING_ATTRIBUTES, WEBHOOK_ATTRIBUTES, RESOURCE_ATTRIBUTES, DOMAIN_ATTRIBUTES].inject(&:merge)

      def self.attribute_names
        ALL_ATTRIBUTES.keys + [:base_urls, :warning_error_classes]
      end

      def self.getters_and_setters
        attribute_names + ALL_ATTRIBUTES.keys.collect{ |k| "#{k}=".to_sym }
      end

      config_name :pact_broker

      attr_config(ALL_ATTRIBUTES)

      def badge_provider_mode= badge_provider_mode
        super(badge_provider_mode&.to_sym)
      end

      def metrics_sql_statement_timeout= metrics_sql_statement_timeout
        super(metrics_sql_statement_timeout&.to_i)
      end

      def warning_error_class_names= warning_error_class_names
        super(value_to_string_array(warning_error_class_names, "warning_error_class_names"))
      end

      def semver_formats= semver_formats
        super(value_to_string_array(semver_formats, "semver_formats"))
      end

      def webhook_retry_schedule= webhook_retry_schedule
        super(value_to_integer_array(webhook_retry_schedule, "webhook_retry_schedule"))
      end

      def webhook_http_method_whitelist= webhook_http_method_whitelist
        super(value_to_string_array(webhook_http_method_whitelist, "webhook_http_method_whitelist"))
      end

      def webhook_http_code_success= webhook_http_code_success
        super(value_to_integer_array(webhook_http_code_success, "webhook_http_code_success"))
      end

      def webhook_scheme_whitelist= webhook_scheme_whitelist
        super(value_to_string_array(webhook_scheme_whitelist, "webhook_scheme_whitelist"))
      end

      def webhook_host_whitelist= webhook_host_whitelist
        super(value_to_string_array(webhook_host_whitelist, "webhook_host_whitelist"))
      end

      def base_urls
        base_url ? base_url.split(" ") : []
      end

      def warning_error_classes
        warning_error_class_names.collect do | class_name |
          begin
            Object.const_get(class_name)
          rescue NameError => e
            logger.warn("Class #{class_name} couldn't be loaded as a warning error class (#{e.class} - #{e.message}). Ignoring.")
            nil
          end
        end.compact
      end

      def log_configuration(logger)
        self.class.attribute_names.sort.each do | setting |
          logger.info "PactBroker.configuration.#{setting}=#{self.send(setting).inspect}"
        end
      end

      private

      def value_to_string_array value, property_name
        if value.is_a?(String)
          PactBroker::Config::SpaceDelimitedStringList.parse(value)
        elsif value.is_a?(Array)
          # parse structured values to possible regexp
          [*value].flat_map do | value |
            if value.is_a?(String)
              PactBroker::Config::SpaceDelimitedStringList.parse(value)
            else
              [value]
            end
          end
        else
          raise ConfigurationError.new("Pact Broker configuration property `#{property_name}` must be a space delimited String or an Array. Got: #{value.inspect}")
        end
      end

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
    end
  end
end
