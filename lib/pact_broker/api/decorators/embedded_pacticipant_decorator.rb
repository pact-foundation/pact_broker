require_relative 'base_decorator'

module PactBroker
  module Api
    module Decorators
      class EmbeddedPacticipantDecorator < BaseDecorator
        camelize_property_names

        property :name

        link :self do | options |
          pacticipant_url(options[:base_url], represented)
        end
      end
    end
  end
end
