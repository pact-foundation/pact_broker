require_relative "base_decorator"
require_relative "pact_pacticipant_decorator"
require_relative "timestamps"

module PactBroker

  module Api

    module Decorators

      class EmbeddedTagDecorator < BaseDecorator

        property :name

        link :self do | options |
          {
            title: "Tag",
            name: represented.name,
            href: tag_url(options[:base_url], represented)
          }
        end

      end
    end
  end
end
