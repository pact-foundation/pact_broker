require "pact_broker/api/decorators/base_decorator"
require "pact_broker/api/decorators/embedded_version_decorator"
require "pact_broker/api/decorators/environment_decorator"

module PactBroker
  module Api
    module Decorators
      class DeployedVersionDecorator < BaseDecorator
        property :uuid
        property :version, :extend => EmbeddedVersionDecorator, writeable: false, embedded: true
        property :environment, :extend => EnvironmentDecorator, writeable: false, embedded: true
        property :currently_deployed, camelize: true
        property :target, camelize: true
        include Timestamps
        property :undeployedAt, getter: lambda { |_|  undeployed_at ? FormatDateTime.call(undeployed_at) : nil }, writeable: false
      end
    end
  end
end
