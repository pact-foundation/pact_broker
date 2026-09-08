# frozen_string_literal: true

module PactBroker
  module Logging
    # Works out which appenders to create, and what to warn the operator about.
    #
    # Kept separate from Setup because the warnings cannot be emitted where they
    # are discovered: we are warning about the very settings that determine where
    # a warning can go. Setup buffers what we return and flushes it once an
    # appender exists to receive it.
    class AppenderEntries
      # Added on the default path only, so that an operator who installs the
      # OpenTelemetry gems gets log correlation without extra configuration.
      # An explicit log_appenders list is authoritative and gets no additions.
      DEFAULT_OTEL_ENTRY = { appender: :open_telemetry, enabled: :auto }.freeze

      DEPRECATED_SETTINGS = [:log_stream, :log_format].freeze

      Resolved = Struct.new(:entries, :warnings)

      def self.call(runtime_configuration)
        new(runtime_configuration).call
      end

      def initialize(runtime_configuration)
        @runtime_configuration = runtime_configuration
      end

      def call
        if runtime_configuration.log_appenders_explicitly_set?
          Resolved.new(runtime_configuration.log_appenders, ignored_setting_warnings)
        else
          Resolved.new(legacy_entries, deprecation_warnings)
        end
      end

      private

      attr_reader :runtime_configuration

      def legacy_entries
        entry = { stream: runtime_configuration.log_stream }
        entry[:format] = runtime_configuration.log_format if runtime_configuration.log_format
        [entry, DEFAULT_OTEL_ENTRY]
      end

      def deprecated_settings_in_use
        DEPRECATED_SETTINGS.select { | name | runtime_configuration.log_setting_explicitly_set?(name) }
      end

      def deprecation_warnings
        names = deprecated_settings_in_use
        return [] if names.empty?

        [
          "#{names.join(" and ")} #{names.size == 1 ? "is" : "are"} deprecated and will be removed in a " \
          "future major version. Use log_appenders instead. The equivalent configuration is:\n" \
          "#{equivalent_log_appenders_yaml}"
        ]
      end

      def ignored_setting_warnings
        names = deprecated_settings_in_use
        return [] if names.empty?

        [
          "#{names.join(" and ")} #{names.size == 1 ? "is" : "are"} being ignored because log_appenders is set. " \
          "Remove #{names.size == 1 ? "it" : "them"}, and configure everything through log_appenders."
        ]
      end

      def equivalent_log_appenders_yaml
        lines = ["log_appenders:"]
        legacy_entries.each_with_index do | entry, index |
          entry.each_with_index do | (key, value), key_index |
            prefix = key_index.zero? ? "  - " : "    "
            lines << "#{prefix}#{key}: #{value}"
          end
          lines << "" if index.zero?
        end
        lines.join("\n")
      end
    end
  end
end
