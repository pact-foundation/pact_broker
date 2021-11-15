require_relative "base_decorator"
require_relative "timestamps"

module PactBroker
  module Api
    module Decorators
      class EmbeddedEnvironmentDecorator < BaseDecorator
        property :uuid, writeable: false
        property :name
        property :display_name, camelize: true
        property :production

        include Timestamps

        link :self do | user_options |
          {
            title: "Environment",
            name: represented.name,
            href: environment_url(represented, user_options.fetch(:base_url))
          }
        end
      end
    end
  end
end
