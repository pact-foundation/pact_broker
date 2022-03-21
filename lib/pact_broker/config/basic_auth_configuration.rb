require "pact_broker/config/runtime_configuration_logging_methods"
require "pact_broker/string_refinements"

module PactBroker
  module Config
    module RuntimeConfigurationBasicAuthMethods
      using PactBroker::StringRefinements

      def self.included(anyway_config)
        anyway_config.class_eval do
          attr_config(
            basic_auth_enabled: false,
            basic_auth_username: nil,
            basic_auth_password: nil,
            basic_auth_read_only_username: nil,
            basic_auth_read_only_password: nil,
            allow_public_read: false,
            public_heartbeat: false
          )

          sensitive_values(:basic_auth_password, :basic_auth_read_only_password)

          coerce_types(
            basic_auth_username: :string,
            basic_auth_password: :string,
            basic_auth_read_only_username: :string,
            basic_auth_read_only_password: :string
          )

          def basic_auth_credentials_provided?
            basic_auth_username&.not_blank? && basic_auth_password&.not_blank?
          end

          def basic_auth_write_credentials
            [basic_auth_username, basic_auth_password]
          end

          def basic_auth_read_credentials
            [basic_auth_read_only_username, basic_auth_read_only_password]
          end
        end
      end
    end
  end
end
