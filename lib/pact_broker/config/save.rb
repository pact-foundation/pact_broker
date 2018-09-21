require 'pact_broker/configuration'
require 'pact_broker/logging'
require 'pact_broker/config/setting'

module PactBroker
  module Config
    class Save

      include SemanticLogger::Loggable

      def self.call configuration, setting_names
        new(configuration, setting_names).call
      end

      def initialize configuration, setting_names
        @configuration = configuration
        @setting_names = setting_names
      end

      def call
        setting_names.each do | setting_name |
          if class_supported?(setting_name)
            create_or_update_setting(setting_name)
          else
            logger.warn "Could not save configuration setting \"#{setting_name}\" to database as the class #{get_value(setting_name).class} is not supported."
          end
        end
      end

      private

      attr_reader :configuration, :setting_names

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
            'boolean'
          when String, nil
            'string'
          when SpaceDelimitedStringList
            'space_delimited_string_list'
          when Array, Hash
            'json'
          when Integer
            'integer'
          when Float
            'float'
          else
            nil
          end
      end

      def get_db_value setting_name
        val = get_value(setting_name)
        case val
        when String, Integer, Float, NilClass
          val
        when TrueClass
          "1"
        when FalseClass
          "0"
        when SpaceDelimitedStringList
          val.to_s
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
