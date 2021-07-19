require "anyway_config"
require "pact_broker/config/runtime_configuration_logging_methods"
require "pact_broker/config/runtime_configuration_database_methods"
require "pact_broker/config/runtime_configuration_coercion_methods"
require "pact_broker/version"

module PactBroker
  module Config
    class RuntimeConfiguration < Anyway::Config
      include RuntimeConfigurationLoggingMethods
      include RuntimeConfigurationDatabaseMethods
      include RuntimeConfigurationCoercionMethods

      class << self
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

      DATABASE_ATTRIBUTES = {
        database_adapter: "postgres",
        database_username: nil,
        database_password: nil,
        database_name: nil,
        database_host: nil,
        database_port: nil,
        database_url: nil,
        database_sslmode: nil,
        sql_log_level: :debug,
        sql_log_warn_duration: 5,
        database_max_connections: nil,
        database_pool_timeout: 5,
        database_connect_max_retries: 0,
        database_timezone: :utc,
        auto_migrate_db: true,
        auto_migrate_db_data: true,
        allow_missing_migration_files: true,
        validate_database_connection_config: true,
        use_case_sensitive_resource_names: true,
        database_statement_timeout: 15,
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
        port: 9292,
        base_url: nil,
        base_urls: [],
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

      def self.getter_and_setter_method_names
        ALL_ATTRIBUTES.keys + ALL_ATTRIBUTES.keys.collect{ |k| "#{k}=".to_sym } + [:warning_error_classes, :database_configuration]  - [:base_url]
      end

      config_name :pact_broker

      attr_config(ALL_ATTRIBUTES)

      sensitive_values(:database_url, :database_password)

      def database_port= database_port
        super(database_port&.to_i)
      end

      def database_connect_max_retries= database_connect_max_retries
        super(database_connect_max_retries&.to_i)
      end

      def database_timezone= database_timezone
        super(database_timezone&.to_sym)
      end

      def sql_log_level= sql_log_level
        super(sql_log_level&.downcase&.to_sym)
      end

      def sql_log_warn_duration= sql_log_warn_duration
        super(sql_log_warn_duration&.to_f)
      end

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

      def base_url= base_url
        super(value_to_string_array(base_url, "base_url"))
      end

      alias_method :original_base_url, :base_url

      def base_url
        raise NotImplementedError
      end

      def base_urls= base_urls
        super(value_to_string_array(base_urls, "base_urls"))
      end

      def base_urls
        (super + [*original_base_url]).uniq
      end

      def warning_error_classes
        warning_error_class_names.collect do | class_name |
          begin
            Object.const_get(class_name)
          rescue NameError => e
            puts("Class #{class_name} couldn't be loaded as a warning error class (#{e.class} - #{e.message}). Ignoring.")
            nil
          end
        end.compact
      end
    end
  end
end
