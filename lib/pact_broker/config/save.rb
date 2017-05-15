require 'pact_broker/configuration'
require 'pact_broker/logging'
require 'pact_broker/config/setting'

module PactBroker
  module Config
    class Save

      include PactBroker::Logging

      SETTING_NAMES = [:order_versions_by_date, :use_case_sensitive_resource_names]

      def self.call configuration
        new(configuration).call
      end

      def initialize configuration
        @configuration = configuration
      end

      def call
        SETTING_NAMES.each do | setting_name |
          if class_supported?(setting_name)
            create_or_update_setting(setting_name)
          else
            logger.warn "Could not save configuration setting \"#{setting_name}\" to database as the class #{get_value(setting_name).class} is not supported."
          end
        end
      end

      private

      attr_reader :configuration

      def create_or_update_setting setting_name
        setting = Setting.find(name: setting_name.to_s) || Setting.new(name: setting_name.to_s)
        setting.type = get_db_type(setting_name)
        setting.value = get_db_value(setting_name)
        setting.save
      end

      def class_supported? setting_name
        !!get_db_type(setting_name)
      end

      def get_db_type setting_name
        val = get_value(setting_name)
        case val
          when true, false
            'Boolean'
          when String, nil
            'String'
          when Array, Hash
            'JSON'
          when Integer
            'Integer'
          when Float
            'Float'
          else
            nil
          end
      end

      def get_db_value setting_name
        val = get_value(setting_name)
        case val
        when String, Integer, Float, TrueClass, FalseClass, NilClass
          val
        when Array, Hash
          val.to_json
        else
          nil
        end
      end

      def get_value setting_name
        configuration.send(setting_name)
      end
    end
  end
end
