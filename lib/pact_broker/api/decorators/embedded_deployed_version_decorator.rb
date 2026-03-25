
module PactBroker
  module Api
    module Decorators
      class EmbeddedDeployedVersionDecorator < BaseDecorator
        property :uuid
        property :currently_deployed, camelize: true
        property :target, camelize: true # deprecated
        property :applicationInstance, getter: lambda { |_| target }
        property :undeployedAt, getter: lambda { |_|  undeployed_at ? FormatDateTime.call(undeployed_at) : nil }, writeable: false

        property :pacticipant, :extend => EmbeddedPacticipantDecorator, writeable: false, embedded: true, if: -> (user_options:, **_other) { user_options[:expand]&.include?(:pacticipant) }
        property :version,     :extend => EmbeddedVersionDecorator,     writeable: false, embedded: true, if: -> (user_options:, **_other) { user_options[:expand]&.include?(:version) }
        property :environment, :extend => EnvironmentDecorator,         writeable: false, embedded: true, if: -> (user_options:, **_other) { user_options[:expand]&.include?(:environment) }

        include Timestamps

        link :self do | user_options |
          {
            href: deployed_version_url(represented, user_options.fetch(:base_url))
          }
        end
      end
    end
  end
end
