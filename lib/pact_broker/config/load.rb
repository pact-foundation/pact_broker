require 'pact_broker/configuration'
require 'pact_broker/logging'
require 'pact_broker/config/setting'

module PactBroker
  module Config
    class Load

      include PactBroker::Logging

      def self.call configuration
        new(configuration).call
      end

      def initialize configuration
        @configuration = configuration
      end

      def call
        Setting.each do | setting |
          set_value_on_configuration setting
        end
      end

      private

      attr_reader :configuration

      def configuration_attribute_exists? setting
        configuration.respond_to?("#{setting.name}=")
      end

      def set_value_on_configuration setting
        if configuration_attribute_exists? setting
          configuration.send("#{setting.name}=", get_value_from_setting(setting))
        else
          logger.warn("Could not load configuration setting \"#{setting.name}\" as there is no matching attribute on the Configuration class")
        end
      end

      def get_value_from_setting setting
        case setting.type
        when 'JSON'
          JSON.parse(setting.value, symbolize_names: true)
        when 'String'
          setting.value
        when 'Integer'
          Integer(setting.value)
        when 'Float'
          Float(setting.value)
        when 'Boolean'
          setting.value == "1"
        end
      end
    end
  end
end
