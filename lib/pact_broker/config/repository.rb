require 'pact_broker/config/setting'

module PactBroker
  module Config
    class Repository

      def create_or_update_setting setting_name, setting_value
        setting = Setting.find(name: setting_name.to_s) || Setting.new(name: setting_name.to_s)
        setting.type = get_db_type(setting_value)
        setting.value = get_db_value(setting_value)
        setting.save
      end

      def class_supported? setting_value
        !!get_db_type(setting_value)
      end

      def get_db_type setting_value
        case setting_value
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

      def get_db_value setting_value
        case setting_value
        when String, Integer, Float, NilClass
          setting_value
        when TrueClass
          "1"
        when FalseClass
          "0"
        when SpaceDelimitedStringList
          setting_value.to_s
        when Array, Hash
          setting_value.to_json
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