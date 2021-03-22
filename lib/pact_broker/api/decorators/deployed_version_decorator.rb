require 'pact_broker/api/decorators/base_decorator'
require 'pact_broker/api/decorators/embedded_version_decorator'
require 'pact_broker/api/decorators/environment_decorator'

module PactBroker
  module Api
    module Decorators
      class DeployedVersionDecorator < BaseDecorator
        property :version, :extend => EmbeddedVersionDecorator, writeable: false, embedded: true
        property :environment, :extend => EnvironmentDecorator, writeable: false, embedded: true
        property :currently_deployed, camelize: true
        property :replaced_previous_deployed_version, camelize: true
        include Timestamps
        property :undeployedAt, getter: lambda { |_|  undeployed_at ? FormatDateTime.call(undeployed_at) : nil }, writeable: false

        link :self do | user_options |
          {
            title: "Deployed version",
            href: deployed_version_url(represented, user_options.fetch(:base_url))
          }
        end
      end
    end
  end
end
