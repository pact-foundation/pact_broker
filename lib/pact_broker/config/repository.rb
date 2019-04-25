require 'pact_broker/config/setting'

module PactBroker
  module Config
    class Repository
      def create_or_update_setting(setting_name, setting_value)
        setting = Setting.find(name: setting_name.to_s) || Setting.new(name: setting_name.to_s)
        setting.set_value_from(setting_value).save
      end

      def class_supported?(setting_value)
        !!Setting.get_db_type(setting_value)
      end
    end
  end
end
