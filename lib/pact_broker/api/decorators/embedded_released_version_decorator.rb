require "pact_broker/api/decorators/base_decorator"
require "pact_broker/api/decorators/embedded_pacticipant_decorator"
require "pact_broker/api/decorators/embedded_version_decorator"
require "pact_broker/api/decorators/environment_decorator"

module PactBroker
  module Api
    module Decorators
      class EmbeddedReleasedVersionDecorator < BaseDecorator
        property :uuid
        property :currently_supported, camelize: true
        include Timestamps
        property :supportEndedAt, getter: lambda { |_|  support_ended_at ? FormatDateTime.call(support_ended_at) : nil }, writeable: false

        property :pacticipant, :extend => EmbeddedPacticipantDecorator, writeable: false, embedded: true, if: -> (user_options:, **_other) { user_options[:expand]&.include?(:pacticipant) }
        property :version,     :extend => EmbeddedVersionDecorator,     writeable: false, embedded: true, if: -> (user_options:, **_other) { user_options[:expand]&.include?(:version) }
        property :environment, :extend => EnvironmentDecorator,         writeable: false, embedded: true, if: -> (user_options:, **_other) { user_options[:expand]&.include?(:environment) }

        link :self do | user_options |
          {
            href: released_version_url(represented, user_options.fetch(:base_url))
          }
        end
      end
    end
  end
end
