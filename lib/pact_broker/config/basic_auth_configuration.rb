require "pact_broker/config/runtime_configuration_logging_methods"

module PactBroker
  module Config
    class BasicAuthRuntimeConfiguration < Anyway::Config
      include RuntimeConfigurationLoggingMethods

      config_name :pact_broker

      attr_config(
        basic_auth_username: nil,
        basic_auth_password: nil,
        basic_auth_read_only_username: nil,
        basic_auth_read_only_password: nil,
        allow_public_read: false,
        public_heartbeat: false
      )

      sensitive_values(:basic_auth_password, :basic_auth_read_only_password)

      def write_credentials
        [basic_auth_username, basic_auth_password]
      end

      def read_credentials
        [basic_auth_read_only_username, basic_auth_read_only_password]
      end

      def use_basic_auth?
        basic_auth_username && basic_auth_password != "" && basic_auth_password && basic_auth_password != ""
      end
    end
  end
end
