require 'pact_broker/configuration'
require 'pact_broker/logging'
require 'pact_broker/config/setting'
require 'pact_broker/config/repository'

module PactBroker
  module Config
    class Save

      include PactBroker::Logging

      def self.call configuration, setting_names
        new(configuration, setting_names).call
      end

      def initialize configuration, setting_names
        @configuration = configuration
        @setting_names = setting_names
        @repository = Config::Repository.new
      end

      def call
        setting_names.each do | setting_name |
          setting_value = get_value(setting_name)
          if repository.class_supported?(setting_value)
            create_or_update_setting(setting_name, setting_value)
          else
            logger.warn "Could not save configuration setting \"#{setting_name}\" to database as the class #{setting_value.class} is not supported."
          end
        end
      end

      private

      attr_reader :configuration, :setting_names, :repository

      def create_or_update_setting setting_name, setting_value
        repository.create_or_update_setting(setting_name, setting_value)
      end

      def get_value setting_name
        configuration.send(setting_name)
      end
    end
  end
end
