require_relative "base_decorator"
require_relative "pact_pacticipant_decorator"
require_relative "timestamps"

module PactBroker
  module Api
    module Decorators
      class LabelDecorator < BaseDecorator

        property :name

        include Timestamps

        # This method is overridden to conditionally render the links based on the user_options
        def to_hash(options)
          hash = super

          unless options.dig(:user_options, :hide_label_decorator_links)
            hash[:_links] = {
              self: {
                title: "Label",
                name: represented.name,
                href: label_url(represented, options.dig(:user_options, :base_url))
              },
              pacticipant: {
                title: "Pacticipant",
                name: represented.pacticipant.name,
                href: pacticipant_url(options.dig(:user_options, :base_url), represented.pacticipant)
              }
            }
          end

          hash
        end
      end
    end
  end
end
