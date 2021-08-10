require "pact_broker/configuration"
require "pact_broker/logging"
require "pact_broker/config/setting"
require "pact_broker/config/space_delimited_string_list"

module PactBroker
  module Config
    class Load

      include PactBroker::Logging

      def self.call runtime_configuration
        new(runtime_configuration).call
      end

      def initialize runtime_configuration
        @runtime_configuration = runtime_configuration
      end

      def call
        Setting.each do | setting |
          set_value_on_configuration setting
        end
      end

      private

      attr_reader :runtime_configuration

      def configuration_attribute_exists? setting
        runtime_configuration.respond_to?("#{setting.name}=")
      end

      def unset_or_value_from_default? setting
        setting_source(setting).nil? || setting_source(setting)[:type] == :defaults
      end

      def setting_source(setting)
        runtime_configuration.to_source_trace.dig(setting.name, :source)
      end

      def set_value_on_configuration setting
        if configuration_attribute_exists?(setting)
          if unset_or_value_from_default?(setting)
            runtime_configuration.send("#{setting.name}=", setting.value_object)
          else
            logger.debug("Ignoring #{setting.name} configuration from database, as it has been set by another source #{setting_source(setting)}")
          end
        else
          logger.warn("Could not load configuration setting \"#{setting.name}\" as there is no matching attribute on the #{runtime_configuration.class} class")
        end
      end
    end
  end
end
