require 'reform'
require 'reform/form'

module PactBroker
  module Api
    module Contracts
      class EnvironmentContract < Reform::Form

        include PactBroker::Messages

        property :name, as: :environment_name

        validation do
          configure do
            # TODO work out how to include the valid environments in the error message
            config.messages_file = File.expand_path("../../../locale/en.yml", __FILE__)

            def self.messages
              super.merge(
                en: { errors: { valid_environment_name?: "must match one of: #{PactBroker.configuration.environments.join(', ')}" } }
              )
            end

            def valid_environment_name?(value)
              allowed_environments.any? && allowed_environments.any?{ | allowed_environment | value =~ /^#{allowed_environment}$/}
            end

            def allowed_environments
              PactBroker.configuration.environments
            end
          end

          required(:name) { valid_environment_name? }
        end
      end
    end
  end
end
