require "anyway_config"
require "pact_broker/config/runtime_configuration_logging_methods"
require "pact_broker/config/runtime_configuration_database_methods"
require "pact_broker/config/runtime_configuration_coercion_methods"
require "pact_broker/version"
require "pact_broker/config/basic_auth_configuration"
require "pact_broker/string_refinements"
require "pact_broker/hash_refinements"
require "pact_broker/error"

module Anyway
  module Tracing
    class << self
      # Override this method so that we get the real caller location, not the forwardable one from
      # the `extend Forwardable` in the PactBroker::Configuration class.
      def current_trace_source
        source_stack.last || accessor_source(caller_locations(2, 2).find { | location | !location.path.end_with?("forwardable.rb") })
      end
    end
  end
end

module PactBroker
  module Config
    class RuntimeConfiguration < Anyway::Config
      using PactBroker::StringRefinements
      using PactBroker::HashRefinements
      include RuntimeConfigurationLoggingMethods
      include RuntimeConfigurationCoercionMethods

      include RuntimeConfigurationDatabaseMethods
      include RuntimeConfigurationBasicAuthMethods

      # logging attributes
      attr_config(
        log_dir: File.expand_path("./log"),
        log_stream: :file,
        log_level: :info,
        log_format: nil,
        warning_error_class_names: ["Sequel::ForeignKeyConstraintViolation"],
        hide_pactflow_messages: false,
        log_configuration_on_startup: true
      )

      on_load :validate_logging_attributes!

      # webhook attributes
      attr_config(
        webhook_retry_schedule: [10, 60, 120, 300, 600, 1200], #10 sec, 1 min, 2 min, 5 min, 10 min, 20 min => 38 minutes
        webhook_http_method_whitelist: ["POST"],
        webhook_http_code_success: [200, 201, 202, 203, 204, 205, 206],
        webhook_scheme_whitelist: ["https"],
        webhook_host_whitelist: [],
        disable_ssl_verification: false,
        user_agent: "Pact Broker v#{PactBroker::VERSION}",
      )

      # resource attributes
      attr_config(
        port: 9292,
        base_url: nil,
        base_urls: [],
        use_hal_browser: true,
        enable_diagnostic_endpoints: true,
        use_rack_protection: true,
        badge_provider_mode: :redirect,
        enable_public_badge_access: false,
        shields_io_base_url: "https://img.shields.io",
        use_case_sensitive_resource_names: true
      )

      # domain attributes
      attr_config(
        order_versions_by_date: true,
        base_equality_only_on_content_that_affects_verification_results: true,
        check_for_potential_duplicate_pacticipant_names: true,
        create_deployed_versions_for_tags: true,
        use_first_tag_as_branch: true,
        use_first_tag_as_branch_time_limit: 10,
        auto_detect_main_branch: true,
        main_branch_candidates: ["develop", "main", "master"],
        allow_dangerous_contract_modification: true,
        semver_formats: ["%M.%m.%p%s%d", "%M.%m", "%M"],
        seed_example_data: true,
        features: []
      )

      def self.getter_and_setter_method_names
        extra_methods = [
          :warning_error_classes,
          :database_configuration,
          :basic_auth_credentials_provided?,
          :basic_auth_write_credentials,
          :basic_auth_read_credentials
        ]
        config_attributes + config_attributes.collect{ |k| "#{k}=".to_sym } + extra_methods  - [:base_url]
      end

      config_name :pact_broker

      sensitive_values(:database_url, :database_password)

      def log_level= log_level
        super(log_level&.downcase&.to_sym)
      end

      def log_stream= log_stream
        super(log_stream&.to_sym)
      end

      def log_format= log_format
        super(log_format&.to_sym)
      end

      def custom_log_formatters= custom_log_formatters
        super(custom_log_formatters&.symbolize_keys)
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

      def badge_provider_mode= badge_provider_mode
        super(badge_provider_mode&.to_sym)
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

      def main_branch_candidates= main_branch_candidates
        super(value_to_string_array(main_branch_candidates, "main_branch_candidates"))
      end

      def features= features
        super(value_to_string_array(features, "features").collect(&:downcase))
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

      def validate_logging_attributes!
        valid_log_streams = [:file, :stdout]
        unless valid_log_streams.include?(log_stream)
          raise_validation_error("log_stream must be one of: #{valid_log_streams.join(", ")}")
        end

        if log_stream == :file && log_dir.blank?
          raise_validation_error("Must specify log_dir if log_stream is set to file")
        end
      end

      def raise_validation_error(msg)
        raise PactBroker::ConfigurationError, msg
      end
    end
  end
end
