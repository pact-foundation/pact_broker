require "anyway_config"

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

require "pact_broker/config/runtime_configuration_logging_methods"
require "pact_broker/config/runtime_configuration_database_methods"
require "pact_broker/config/runtime_configuration_coercion_methods"
require "pact_broker/version"
require "pact_broker/config/runtime_configuration_basic_auth_methods"
require "pact_broker/string_refinements"
require "pact_broker/hash_refinements"
require "pact_broker/error"
require "pact_broker/logging/appender_factory"

module PactBroker
  module Config
    class RuntimeConfiguration < Anyway::Config
      using PactBroker::StringRefinements
      using PactBroker::HashRefinements
      include RuntimeConfigurationLoggingMethods
      include RuntimeConfigurationCoercionMethods

      include RuntimeConfigurationDatabaseMethods
      include RuntimeConfigurationBasicAuthMethods

      config_name :pact_broker

      # logging attributes
      attr_config(
        log_dir: File.expand_path("./log"),
        log_stream: :file,
        log_level: :info,
        log_format: nil,
        log_application: nil,
        log_environment: nil,
        warning_error_class_names: ["Sequel::ForeignKeyConstraintViolation"],
        hide_pactflow_messages: false,
        log_configuration_on_startup: true,
        http_debug_logging_enabled: false
      )

      # No default. See the comment on webhook_certificates: a default of [] or
      # nil makes anyway_config fail when merging the numerically indexed hash
      # from the environment variables. nil therefore means "not configured",
      # which is what Logging::AppenderEntries uses to decide whether to fall
      # back to the deprecated log_stream and log_format settings.
      attr_config :log_appenders

      on_load :validate_logging_attributes!

      # webhook attributes
      attr_config(
        webhook_retry_schedule: [10, 60, 120, 300, 600, 1200], #10 sec, 1 min, 2 min, 5 min, 10 min, 20 min => 38 minutes
        webhook_http_method_whitelist: ["POST"],
        webhook_http_code_success: [200, 201, 202, 203, 204, 205, 206],
        webhook_scheme_whitelist: ["https"],
        webhook_host_whitelist: [],
        webhook_redact_sensitive_data: true,
        disable_ssl_verification: false,
        user_agent: "Pact Broker v#{PactBroker::VERSION}"
      )
      # no default, if you set it to [] or nil, then anyway config blows up when it tries to merge in the
      # numerically indexed hash from the environment variables.
      attr_config :webhook_certificates
      on_load :set_webhook_attribute_defaults

      # resource attributes
      attr_config(
        port: 9292,
        base_url: nil,
        base_urls: [],
        use_hal_browser: true,
        enable_diagnostic_endpoints: true,
        use_rack_protection: true,
        rack_protection_use: nil,
        rack_protection_except: [:path_traversal, :remote_token, :session_hijacking, :http_origin], # Beth: not sure why these are disabled
        badge_provider_mode: :redirect,
        enable_public_badge_access: false,
        shields_io_base_url: "https://img.shields.io",
        badge_default_cache_setting: "max-age=30",
        use_case_sensitive_resource_names: true,
        pact_content_diff_timeout: 15
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
        allow_dangerous_contract_modification: false,
        semver_formats: ["%M.%m.%p%s%d", "%M.%m", "%M"],
        seed_example_data: true,
        network_diagram_max_pacticipants: 150,
        features: {}
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

      coerce_types(
        features: COERCE_FEATURES,
        network_diagram_max_pacticipants: :integer,
        webhook_certificates: COERCE_WEBHOOKS,
        log_appenders: COERCE_LOG_APPENDERS
      )
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

      def log_appenders= log_appenders
        super(COERCE_LOG_APPENDERS.call(log_appenders))
        validate_log_appenders!
      end

      # attr_config defaults are evaluated once, when the class is defined, so a
      # default of ENV.fetch("OTEL_SERVICE_NAME", ...) would be baked in at load
      # time and never see a later change to the environment variable. Falling
      # back in the getter keeps it dynamic.
      def log_application
        super || ENV.fetch("OTEL_SERVICE_NAME", "pact-broker")
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

      def rack_protection_use= rack_protection_use
        super(value_to_string_array(rack_protection_use, "rack_protection_use")&.collect(&:to_sym))
      end

      def rack_protection_except= rack_protection_except
        super(value_to_string_array(rack_protection_except, "rack_protection_except")&.collect(&:to_sym))
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

        validate_log_appenders!
      end

      def validate_log_appenders!
        return if log_appenders.nil?

        log_appenders.each_with_index do | entry, index |
          validate_log_appender_entry!(entry, index)
        end
      end
      private :validate_log_appenders!

      def validate_log_appender_entry!(entry, index)
        error = lambda { | message | raise_validation_error("log_appenders entry #{index} #{message}") }

        has_stream = !entry[:stream].nil?
        has_appender = !entry[:appender].nil?
        # io:, file_name: and logger: are the other keys SemanticLogger dispatches on
        has_direct_target = [:io, :file_name, :logger].any? { | key | !entry[key].nil? }

        error.call("must not specify both stream and appender") if has_stream && has_appender

        unless has_stream || has_appender || has_direct_target
          error.call("must specify one of stream or appender")
        end

        if has_stream && !PactBroker::Logging::AppenderFactory::VALID_STREAMS.include?(entry[:stream])
          error.call("has an invalid stream. Valid values are: #{PactBroker::Logging::AppenderFactory::VALID_STREAMS.join(", ")}")
        end

        if entry[:format] && !PactBroker::Logging::AppenderFactory::VALID_FORMATS.include?(entry[:format])
          error.call("has an invalid format. Valid values are: #{PactBroker::Logging::AppenderFactory::VALID_FORMATS.join(", ")}")
        end

        if entry[:file_name] && has_stream && entry[:stream] != :file
          error.call("must not specify file_name unless stream is file")
        end

        unless [true, false, :auto].include?(entry.fetch(:enabled, true))
          error.call("has an invalid enabled value. Valid values are: true, false, auto")
        end
      end
      private :validate_log_appender_entry!

      def log_appenders_explicitly_set?
        !log_appenders.nil?
      end

      def log_setting_explicitly_set?(name)
        trace = to_source_trace[name.to_s]
        return false unless trace

        trace.dig(:source, :type) != :defaults
      end

      def raise_validation_error(msg)
        raise PactBroker::ConfigurationError, msg
      end

      def set_webhook_attribute_defaults
        # can't set a default on this, or anyway config blows up when trying to merge the
        # hash from the env vars into an array/nil.
        if webhook_certificates.nil?
          self.webhook_certificates = []
        end
      end
    end
  end
end
